import Foundation

actor LiveGitService: GitServiceProtocol {

    var executable = "/usr/bin/git"
    let access = SecurityScopedAccessController()
    var activeRepositories = Set<String>()

    var runner: GitProcessRunner {
        GitProcessRunner(executable: self.executable)
    }

    func executableStatus() async -> GitExecutableStatus {

        do {

            let result = try await self.runner.run(["--version"], directory: FileManager.default.temporaryDirectory)
            return GitExecutableStatus(path: self.executable, version: result.trimmed, problem: nil, isCustomPath: self.executable != "/usr/bin/git")

        } catch {
            return GitExecutableStatus(path: self.executable, version: nil, problem: error.localizedDescription, isCustomPath: self.executable != "/usr/bin/git")
        }

    }

    func configureExecutable(customPath: String?) async -> GitExecutableStatus {

        guard self.activeRepositories.isEmpty else {
            return GitExecutableStatus(path: self.executable, version: nil, problem: "Wait for the current Git operation to finish.", isCustomPath: true)
        }

        self.executable = customPath?.isEmpty == false ? customPath ?? "/usr/bin/git" : "/usr/bin/git"
        return await executableStatus()

    }

    func locateRepository(_ repository: GitRepositoryReference) async throws -> GitRepositoryLocation {

        let url = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let result = try await self.runner.run(["rev-parse", "--show-toplevel", "--absolute-git-dir", "--path-format=absolute", "--git-common-dir"], directory: url, acceptsFailure: true)
        let lines = result.trimmed.components(separatedBy: "\n")

        guard result.status == 0, lines.count >= 3 else {
            throw GitError.notRepository(path: url.path)
        }

        return GitRepositoryLocation(rootPath: lines[0], gitDirectoryPath: lines[1], commonDirectoryPath: lines[2])

    }

    func snapshot(
        of repository: GitRepositoryReference,
        scope: GitSnapshotScope,
        previous: GitRepositorySnapshot?
    ) async throws -> GitRepositorySnapshot {

        let location = try await locateRepository(repository)
        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let root = URL(fileURLWithPath: location.rootPath)
        let status = try await self.runner.run(["status", "--porcelain=v1", "-z", "--untracked-files=all"], directory: root)
        let branch = try await self.runner.run(["symbolic-ref", "--quiet", "--short", "HEAD"], directory: url, acceptsFailure: true)
        let head = try await self.runner.run(["rev-parse", "--verify", "HEAD"], directory: url, acceptsFailure: true)
        let changes = GitOutputParser.changes(status.text)
        let state = GitHeadState(branchName: branch.status == 0 ? branch.trimmed : nil, commitID: head.status == 0 ? head.trimmed : nil)
        let upstream = try await upstream(at: root, branch: state.branchName)
        let fetchDate = try? URL(fileURLWithPath: location.gitDirectoryPath)
            .appendingPathComponent("FETCH_HEAD")
            .resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate

        if scope == .status {

            let snapshot = GitRepositorySnapshot(
                location: location, head: state, upstream: upstream, operation: operation(at: location),
                changes: changes, remotes: [], branches: [], tags: [], recentCommits: [],
                capturedAt: Date(), referencesCapturedAt: nil, lastFetchAt: fetchDate
            )
            return previous?.replacingStatus(with: snapshot) ?? snapshot

        }

        let branches = try await branchReferences(at: root, limit: scope == .initial ? 30 : nil, currentBranch: state.branchName)
        let tags = try await self.runner.run(["for-each-ref", "--format=%(refname:short)%00%(objectname)", "refs/tags"], directory: root)
        let commits = state.isUnborn ? [] : try await commits(in: repository, revision: nil, limit: 50)

        return GitRepositorySnapshot(
            location: location,
            head: state,
            upstream: upstream,
            operation: operation(at: location),
            changes: changes,
            remotes: try await remotes(at: root),
            branches: branches,
            tags: tags.text.split(separator: "\n").compactMap { line in

                let fields = line.components(separatedBy: "\0")
                return fields.count == 2 ? RepositoryTag(name: fields[0], commitID: fields[1]) : nil

            },
            recentCommits: commits,
            capturedAt: Date(),
            referencesCapturedAt: Date(),
            lastFetchAt: fetchDate
        )

    }

    func branches(in repository: GitRepositoryReference) async throws -> [RepositoryBranch] {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let root = try await repositoryRoot(at: selectedURL)
        return try await branchReferences(at: root, limit: nil, currentBranch: nil)

    }

    private func branchReferences(at root: URL, limit: Int?, currentBranch: String?) async throws -> [RepositoryBranch] {

        var arguments = ["for-each-ref", "--format=%(refname)%00%(objectname)%00%(upstream:short)%00%(HEAD)%00%(committerdate:unix)"]
        if let limit { arguments.append("--count=\(limit + 10)") }
        arguments += ["refs/heads", "refs/remotes"]
        let result = try await self.runner.run(arguments, directory: root)
        let branches = GitOutputParser.branches(result.text)
        guard let limit else { return branches }

        var initial = Array(branches.prefix(limit))
        if let currentBranch, !initial.contains(where: { $0.isCurrent }) {

            let current = try await self.runner.run(
                ["for-each-ref", "--format=%(refname)%00%(objectname)%00%(upstream:short)%00%(HEAD)%00%(committerdate:unix)", "refs/heads/\(currentBranch)"],
                directory: root
            )

            if let branch = GitOutputParser.branches(current.text).first(where: { $0.name == currentBranch }) {
                if initial.isEmpty {
                    initial.append(branch)
                } else {
                    initial[initial.count - 1] = branch
                }
            }

        }

        return initial

    }

    func operation(at location: GitRepositoryLocation) -> GitOperationState {

        let directory = URL(fileURLWithPath: location.gitDirectoryPath)
        let manager = FileManager.default

        for name in ["rebase-merge", "rebase-apply"] where manager.fileExists(atPath: directory.appendingPathComponent(name).path) {
            return .rebasing(onto: nil, step: nil, total: nil)
        }

        if manager.fileExists(atPath: directory.appendingPathComponent("MERGE_HEAD").path) {
            return .merging(incoming: nil)
        }

        if manager.fileExists(atPath: directory.appendingPathComponent("CHERRY_PICK_HEAD").path) {
            return .cherryPicking
        }

        return manager.fileExists(atPath: directory.appendingPathComponent("REVERT_HEAD").path) ? .reverting : .none

    }

    private func upstream(at root: URL, branch: String?) async throws -> GitUpstreamStatus? {

        guard let branch else {
            return nil
        }

        let name = try await self.runner.run(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"], directory: root, acceptsFailure: true)

        guard name.status == 0 else {
            return nil
        }

        let counts = try await self.runner.run(["rev-list", "--left-right", "--count", "HEAD...@{upstream}"], directory: root)
        let values = counts.trimmed.split(whereSeparator: \.isWhitespace).compactMap { Int($0) }
        let remote = try await self.runner.run(["config", "--get", "branch.\(branch).remote"], directory: root, acceptsFailure: true)

        return GitUpstreamStatus(name: name.trimmed, remoteName: remote.status == 0 ? remote.trimmed : nil, ahead: values.first ?? 0, behind: values.last ?? 0)

    }

    private func remotes(at root: URL) async throws -> [GitRemote] {

        let result = try await self.runner.run(["remote"], directory: root)
        var remotes: [GitRemote] = []

        for name in result.text.split(separator: "\n").map(String.init) {

            let fetch = try await self.runner.run(["remote", "get-url", "--", name], directory: root)
            let push = try await self.runner.run(["remote", "get-url", "--push", "--", name], directory: root)
            remotes.append(GitRemote(name: name, fetchURL: GitProcessRunner.sanitize(fetch.trimmed), pushURL: GitProcessRunner.sanitize(push.trimmed)))

        }

        return remotes

    }

    func commits(in repository: GitRepositoryReference, revision: String?, limit: Int) async throws -> [RepositoryCommit] {
        try await log(in: repository, revision: revision, path: nil, limit: limit)
    }

    func fileHistory(
        in repository: GitRepositoryReference,
        revision: String?,
        path: String,
        limit: Int
    ) async throws -> [RepositoryCommit] {

        try await log(in: repository, revision: revision, path: path, limit: limit)

    }

    private func log(in repository: GitRepositoryReference, revision: String?, path: String?, limit: Int) async throws -> [RepositoryCommit] {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        var arguments = ["log", "-\(min(500, max(1, limit)))", "--format=%H%x1f%P%x1f%an%x1f%at%x1f%s%x00"]

        if path != nil {
            arguments.append("--follow")
        }

        if let revision {
            arguments.append(try await resolvedRevision(revision, at: url))
        }

        arguments.append("--")

        if let path {

            try validatePath(path)
            arguments.append(path)

        }

        let result = try await self.runner.run(arguments, directory: url)
        return GitOutputParser.commits(result.text)

    }

    func resolvedRevision(_ revision: String, at url: URL) async throws -> String {

        let result = try await self.runner.run(["rev-parse", "--verify", "--end-of-options", revision + "^{commit}"], directory: url, acceptsFailure: true)

        guard result.status == 0 else {
            throw GitError.invalidRevision(revision)
        }

        return result.trimmed

    }

    func repositoryRoot(at directory: URL) async throws -> URL {

        let result = try await self.runner.run(["rev-parse", "--show-toplevel"], directory: directory, acceptsFailure: true)

        guard result.status == 0 else { throw GitError.notRepository(path: directory.path) }
        return URL(fileURLWithPath: result.trimmed, isDirectory: true)

    }

    func validatePath(_ path: String) throws {

        guard !path.isEmpty, !path.hasPrefix("/"), !path.split(separator: "/").contains(".."), !path.contains("\0") else {
            throw GitError.invalidPath(path)
        }

    }

    func suggestedPullStrategy(in repository: GitRepositoryReference) async -> GitPullStrategy {
        .fastForwardOnly
    }

}
