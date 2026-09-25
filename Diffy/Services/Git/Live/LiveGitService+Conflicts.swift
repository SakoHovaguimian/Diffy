import Foundation
import CryptoKit

extension LiveGitService {

    func conflictDocument(in repository: GitRepositoryReference, path: String) async throws -> GitConflictDocument {

        try validatePath(path)
        let snapshot = try await snapshot(of: repository, scope: .status, previous: nil)

        guard let conflict = snapshot.change(at: path)?.conflict else {
            throw GitError.unsupported("This file is no longer conflicted. Refresh the repository.")
        }

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let base = try await self.runner.run(["show", ":1:" + path], directory: url, acceptsFailure: true).data
        let ours = try await self.runner.run(["show", ":2:" + path], directory: url, acceptsFailure: true).data
        let theirs = try await self.runner.run(["show", ":3:" + path], directory: url, acceptsFailure: true).data
        let yours: Data
        let incoming: Data

        if case .rebasing = snapshot.operation {

            yours = theirs
            incoming = ours

        } else {

            yours = ours
            incoming = theirs

        }

        let isBinary = [base, yours, incoming].contains { $0.contains(0) || String(data: $0, encoding: .utf8) == nil }
        let segment = MergeConflict(id: 0, title: path, base: String(decoding: base, as: UTF8.self), yours: String(decoding: yours, as: UTF8.self), theirs: String(decoding: incoming, as: UTF8.self))
        let fingerprint = SHA256.hash(data: base + yours + incoming).map { String(format: "%02x", $0) }.joined()

        return GitConflictDocument(path: path, kind: conflict, operation: snapshot.operation, baseLabel: "Base", yoursLabel: "Your changes", theirsLabel: "Incoming changes", segments: [.conflict(segment)], isBinary: isBinary, baseSize: base.count, yoursSize: yours.count, theirsSize: incoming.count, fingerprint: fingerprint)

    }

    func applyMergeResult(_ content: String, path: String, stagesResult: Bool, in repository: GitRepositoryReference) async throws {

        try validatePath(path)
        let location = try await locateRepository(repository)

        guard self.activeRepositories.insert(location.commonDirectoryPath).inserted else {
            throw GitError.unsupported("Another operation is running in this repository.")
        }

        defer { self.activeRepositories.remove(location.commonDirectoryPath) }
        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let url = try await repositoryRoot(at: selectedURL)
        let destination = URL(fileURLWithPath: location.rootPath).appendingPathComponent(path)

        guard destination.resolvingSymlinksInPath().path == destination.standardizedFileURL.path else {
            throw GitError.invalidPath(path)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
        try Data(content.utf8).write(to: destination, options: .atomic)

        if let permissions = attributes[.posixPermissions] {
            try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: destination.path)
        }

        if stagesResult {
            _ = try await self.runner.run(["add", "--", path], directory: url)
        }

    }

}
