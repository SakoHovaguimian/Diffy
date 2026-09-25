import Foundation

extension LiveGitService {

    // MARK: - Explicitly Reviewed AI Proposals

    func applyReviewedAIPatch(_ request: GitAIPatchRequest, in repository: GitRepositoryReference) async throws {

        try self.validateAIProposal(request)
        let location = try await self.locateRepository(repository)

        guard self.activeRepositories.insert(location.commonDirectoryPath).inserted else {
            throw GitError.unsupported("Another operation is running in this repository.")
        }

        defer { self.activeRepositories.remove(location.commonDirectoryPath) }
        _ = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let root = URL(fileURLWithPath: location.rootPath, isDirectory: true)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("diffy-reviewed-patch-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let patchURL = directory.appendingPathComponent("proposal.patch")
        try Data(request.patch.utf8).write(to: patchURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: patchURL.path)

        let paths = try await self.proposalPaths(patchURL: patchURL, root: root)
        let allowed = Set(request.allowedPaths)

        guard !paths.isEmpty, Set(paths) == allowed else {
            throw GitError.unsupported("The patch paths do not match the files shown in the proposal. Regenerate the fix plan.")
        }

        try self.validateProposalDestinations(paths, root: root)
        try await self.validateProposalCheckout(request, paths: paths, repository: repository)
        _ = try await self.runner.run(["apply", "--check", "--whitespace=nowarn", "--", patchURL.path], directory: root)
        try Task.checkCancellation()
        // Recheck after validation so a checkout or edit during preview cannot be silently overwritten.
        try await self.validateProposalCheckout(request, paths: paths, repository: repository)
        try self.validateProposalDestinations(paths, root: root)
        _ = try await self.runner.run(["apply", "--whitespace=nowarn", "--", patchURL.path], directory: root)

    }

    private func validateAIProposal(_ request: GitAIPatchRequest) throws {

        guard !request.patch.isEmpty, request.patch.utf8.count <= 500_000,
              !request.patch.contains("\0"), !request.allowedPaths.isEmpty,
              request.allowedPaths.count <= 28,
              request.expectedHeadSHA.range(of: "^[a-fA-F0-9]{40,64}$", options: .regularExpression) != nil else {
            throw GitError.unsupported("This proposal is missing a valid revision, patch, or file list.")
        }

        let forbiddenHeaders = [
            "GIT binary patch", "Binary files ", "rename from ", "rename to ", "copy from ", "copy to ",
            "old mode ", "new mode ", "new file mode 120000", "new file mode 160000"
        ]

        guard !request.patch.components(separatedBy: .newlines).contains(where: { line in
            forbiddenHeaders.contains { line.hasPrefix($0) }
        }) else {
            throw GitError.unsupported("AI Apply supports text patches. Review binary, rename, link, and file-mode changes manually.")
        }

        for path in request.allowedPaths {

            try self.validatePath(path)

            guard !path.split(separator: "/").contains(where: { $0.lowercased() == ".git" }) else {
                throw GitError.invalidPath(path)
            }

        }

    }

    private func proposalPaths(patchURL: URL, root: URL) async throws -> [String] {

        let result = try await self.runner.run(["apply", "--numstat", "-z", "--", patchURL.path], directory: root)

        return try result.text.split(separator: "\0").map { record in

            let fields = record.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)

            guard fields.count == 3, Int(fields[0]) != nil, Int(fields[1]) != nil, !fields[2].isEmpty else {
                throw GitError.unsupported("The proposal is not a supported text patch.")
            }

            return String(fields[2])

        }

    }

    private func validateProposalDestinations(_ paths: [String], root: URL) throws {

        for path in paths {

            try self.validatePath(path)
            let destination = root.appendingPathComponent(path)
            let resolved = destination.resolvingSymlinksInPath().standardizedFileURL.path
            let expected = root.resolvingSymlinksInPath().appendingPathComponent(path).standardizedFileURL.path

            guard resolved == expected else {
                throw GitError.unsupported("The proposal includes a symbolic-link path. Review it manually.")
            }

        }

    }

    private func validateProposalCheckout(
        _ request: GitAIPatchRequest,
        paths: [String],
        repository: GitRepositoryReference
    ) async throws {

        let snapshot = try await self.snapshot(of: repository, scope: .status, previous: nil)

        guard snapshot.head.commitID == request.expectedHeadSHA else {
            throw GitError.unsupported("This checkout is not at the analyzed PR head. Check out that revision and review the proposal again.")
        }

        guard snapshot.operation == .none else {
            throw GitError.operationInProgress(snapshot.operation)
        }

        let affected = Set(paths)
        let dirty = snapshot.changes.filter {
            affected.contains($0.path) || $0.originalPath.map(affected.contains) == true
        }

        guard dirty.isEmpty else {
            throw GitError.dirtyWorkingTree(paths: dirty.map(\.path))
        }

    }

}
