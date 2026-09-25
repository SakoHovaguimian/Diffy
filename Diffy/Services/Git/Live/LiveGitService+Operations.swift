import Foundation

extension LiveGitService {

    func perform(
        _ request: GitOperationRequest,
        in repository: GitRepositoryReference,
        progress: @escaping @Sendable (GitOperationProgress) -> Void
    ) async throws -> GitOperationResult {

        let location = try await locateRepository(repository)

        guard self.activeRepositories.insert(location.commonDirectoryPath).inserted else {
            throw GitError.unsupported("Another operation is running in this repository. Wait for it to finish.")
        }

        defer { self.activeRepositories.remove(location.commonDirectoryPath) }
        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let root = URL(fileURLWithPath: location.rootPath)
        let state = try await snapshot(of: repository, scope: .full, previous: nil)
        try validateOperation(request, snapshot: state)
        let arguments = try await operationArguments(request, at: root, snapshot: state)
        progress(GitOperationProgress(phase: request.title))
        let result = try await self.runner.run(arguments, directory: url, acceptsFailure: true, timeout: request.usesNetwork ? 600 : 120)

        guard result.status == 0 else {

            let updated = try await snapshot(of: repository, scope: .full, previous: state)

            if request.canPauseForConflicts && !updated.conflicts.isEmpty {
                return GitOperationResult(message: "\(request.title) paused. Resolve and stage the conflicted files, then continue.", stoppedForConflicts: true)
            }

            throw GitError.commandFailed(GitCommandFailure(subcommand: arguments.first ?? "", exitStatus: result.status, message: result.error))

        }

        let comparison = await operationComparison(for: request, before: state, in: repository)
        return GitOperationResult(message: "\(request.title) completed.", comparison: comparison)

    }

    private func validateOperation(_ request: GitOperationRequest, snapshot: GitRepositorySnapshot) throws {

        switch request {

        case .stage, .unstage, .resolveConflict, .continueRebase, .abortRebase, .continueMerge, .abortMerge:
            break

        default:
            if snapshot.operation.isInProgress {
                throw GitError.operationInProgress(snapshot.operation)
            }

        }

        switch request {

        case .pull, .startRebase, .startMerge, .switchBranch, .createBranch:
            guard snapshot.isClean else {
                throw GitError.dirtyWorkingTree(paths: snapshot.changes.map(\.path))
            }

        case .commit, .continueMerge, .continueRebase:
            guard snapshot.conflicts.isEmpty else {
                throw GitError.unresolvedConflicts(paths: snapshot.conflicts.map(\.path))
            }

        default:
            break

        }

        switch request {

        case .push, .pull, .startRebase:
            guard !snapshot.head.isDetached else {
                throw GitError.detachedHead
            }

        default:
            break

        }

    }

    private func operationArguments(_ request: GitOperationRequest, at root: URL, snapshot: GitRepositorySnapshot) async throws -> [String] {

        switch request {

        case let .commit(message):
            guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !snapshot.stagedChanges.isEmpty else {
                throw GitError.unsupported("Stage at least one file and enter a commit message.")
            }

            return ["commit", "-m", message]

        case let .createBranch(name):
            try await validateBranch(name, at: root)
            return ["switch", "-c", name]

        case let .fetch(remote):
            if let remote {

                try validateRemote(remote, snapshot: snapshot)
                return ["fetch", "--", remote]

            }

            return ["fetch", "--all"]

        case let .push(options):
            return try pushArguments(options, snapshot: snapshot)

        case let .pull(strategy):
            guard snapshot.upstream != nil else {
                throw GitError.missingUpstream(branch: snapshot.head.displayName)
            }

            switch strategy {

            case .fastForwardOnly: return ["pull", "--ff-only"]
            case .rebase: return ["pull", "--rebase", "--no-autostash"]
            case .merge: return ["pull", "--no-rebase", "--no-edit"]

            }

        case let .startRebase(onto):
            return ["rebase", "--no-autostash", try await resolvedRevision(onto, at: root)]

        case .continueRebase:
            guard case .rebasing = snapshot.operation else { throw GitError.nothingInProgress }
            return ["rebase", "--continue"]

        case .abortRebase:
            guard case .rebasing = snapshot.operation else { throw GitError.nothingInProgress }
            return ["rebase", "--abort"]

        case let .startMerge(branch):
            return ["merge", "--no-edit", try await resolvedRevision(branch, at: root)]

        case .continueMerge:
            guard case .merging = snapshot.operation else { throw GitError.nothingInProgress }
            return ["commit", "--no-edit"]

        case .abortMerge:
            guard case .merging = snapshot.operation else { throw GitError.nothingInProgress }
            return ["merge", "--abort"]

        case let .stage(paths):
            try validatePaths(paths)
            return ["add", "--"] + paths

        case let .unstage(paths):
            try validatePaths(paths)
            let originalPaths = paths.compactMap { snapshot.change(at: $0)?.originalPath }
            let affectedPaths = Array(Set(paths + originalPaths)).sorted()
            return snapshot.head.isUnborn ? ["rm", "--cached", "--"] + affectedPaths : ["restore", "--staged", "--"] + affectedPaths

        case let .restore(paths):
            try validatePaths(paths)

            guard paths.allSatisfy({ snapshot.change(at: $0)?.isUntracked == false }) else {
                throw GitError.unsupported("Untracked files are never deleted by Discard Changes.")
            }

            return ["restore", "--worktree", "--"] + paths

        case let .resolveConflict(path, choice, stagesResult):
            try validatePath(path)
            let rebasing: Bool

            if case .rebasing = snapshot.operation {
                rebasing = true
            } else {
                rebasing = false
            }

            let takesOurs = (choice == .yours) != rebasing
            _ = try await self.runner.run(["checkout", takesOurs ? "--ours" : "--theirs", "--", path], directory: root)
            return stagesResult ? ["add", "--", path] : ["status", "--porcelain=v1"]

        case let .switchBranch(name):
            guard snapshot.localBranches.contains(where: { $0.name == name }) else {
                throw GitError.invalidRevision(name)
            }

            return ["switch", "--", name]

        }

    }

    private func pushArguments(_ options: GitPushOptions, snapshot: GitRepositorySnapshot) throws -> [String] {

        var arguments = ["push"]

        if options.forceWithLease {
            arguments.append("--force-with-lease")
        }

        if options.setsUpstream {

            guard let remote = options.remote, let branch = snapshot.head.branchName else {
                throw GitError.missingUpstream(branch: snapshot.head.displayName)
            }

            try validateRemote(remote, snapshot: snapshot)
            return arguments + ["--set-upstream", "--", remote, "HEAD:refs/heads/\(branch)"]

        }

        guard snapshot.upstream != nil else {
            throw GitError.missingUpstream(branch: snapshot.head.displayName)
        }

        return arguments

    }

    private func validateRemote(_ remote: String, snapshot: GitRepositorySnapshot) throws {

        guard snapshot.remotes.contains(where: { $0.name == remote }), !remote.hasPrefix("-") else {
            throw GitError.unsupported("Choose a configured remote.")
        }

    }

    private func validateBranch(_ name: String, at root: URL) async throws {

        guard !name.hasPrefix("-"), !name.isEmpty else {
            throw GitError.invalidRevision(name)
        }

        let result = try await self.runner.run(["check-ref-format", "--branch", name], directory: root, acceptsFailure: true)

        guard result.status == 0 else {
            throw GitError.invalidRevision(name)
        }

    }

    private func validatePaths(_ paths: [String]) throws {

        guard !paths.isEmpty else {
            throw GitError.unsupported("Select at least one file.")
        }

        try paths.forEach(validatePath)

    }

    func clone(_ request: GitCloneRequest, progress: @escaping @Sendable (GitOperationProgress) -> Void) async throws -> URL {

        guard !request.directoryName.isEmpty, request.directoryName != ".", request.directoryName != "..",
              !request.directoryName.contains("/"), !request.directoryName.contains("\0") else {
            throw GitError.invalidPath(request.directoryName)
        }

        guard !FileManager.default.fileExists(atPath: request.destination.path) else {
            throw GitError.destinationExists(path: request.destination.path)
        }

        guard let coordinate = GitHubRepositoryCoordinate(remoteURL: request.remoteURL),
              request.remoteURL == "https://\(coordinate.host)/\(coordinate.fullName).git" || request.remoteURL == "git@\(coordinate.host):\(coordinate.fullName).git" else {
            throw GitError.unsupported("Choose an HTTPS or SSH GitHub repository URL without embedded credentials.")
        }

        let started = request.parentDirectory.startAccessingSecurityScopedResource()
        defer { if started { request.parentDirectory.stopAccessingSecurityScopedResource() } }
        progress(GitOperationProgress(phase: "Cloning \(request.directoryName)"))
        _ = try await self.runner.run(["clone", "--", request.remoteURL, request.directoryName], directory: request.parentDirectory, timeout: 600)
        return request.destination

    }

    func fetchPullRequestSources(
        _ pullRequest: PullRequestSummary,
        remoteName: String,
        in repository: GitRepositoryReference,
        progress: @escaping @Sendable (GitOperationProgress) -> Void
    ) async throws -> ComparisonSelection {

        let location = try await locateRepository(repository)

        guard self.activeRepositories.insert(location.commonDirectoryPath).inserted else {
            throw GitError.unsupported("Another operation is running in this repository.")
        }

        defer { self.activeRepositories.remove(location.commonDirectoryPath) }

        guard [pullRequest.baseSHA, pullRequest.headSHA].allSatisfy({ value in
            [40, 64].contains(value.count) && value.allSatisfy(\.isHexDigit)
        }) else {
            throw GitError.invalidRevision("Pull request commit")
        }

        let snapshot = try await snapshot(of: repository, scope: .full, previous: nil)
        try validateRemote(remoteName, snapshot: snapshot)
        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        progress(GitOperationProgress(phase: "Fetching pull request #\(pullRequest.number)"))
        _ = try await self.runner.run(["fetch", "--no-tags", "--", remoteName, "refs/pull/\(pullRequest.number)/head", pullRequest.baseSHA], directory: url, timeout: 600)
        return ComparisonSelection(left: .revision(pullRequest.baseSHA), right: .revision(pullRequest.headSHA), usesMergeBase: true)

    }

}
