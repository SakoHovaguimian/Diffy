import Foundation

/// The last successful read of a repository. Git remains the source of truth; this value
/// is what the interface shows and what the live cache stores for immediate launch.
struct GitRepositorySnapshot: Codable, Hashable, Sendable {
    let location: GitRepositoryLocation
    let head: GitHeadState
    let upstream: GitUpstreamStatus?
    let operation: GitOperationState
    let changes: [GitFileChange]
    let remotes: [GitRemote]
    let branches: [RepositoryBranch]
    let tags: [RepositoryTag]
    let recentCommits: [RepositoryCommit]
    let capturedAt: Date
    var referencesCapturedAt: Date?

    // MARK: - Changes

    var stagedChanges: [GitFileChange] {
        self.changes.filter(\.hasStagedChanges)
    }

    var unstagedChanges: [GitFileChange] {
        self.changes.filter(\.hasUnstagedChanges)
    }

    var conflicts: [GitConflict] {

        self.changes.compactMap { change in
            change.conflict.map { GitConflict(path: change.path, kind: $0) }
        }

    }

    var isClean: Bool {
        self.changes.isEmpty
    }

    var isEmptyRepository: Bool {
        self.head.isUnborn
    }

    func change(at path: String) -> GitFileChange? {
        self.changes.first { $0.path == path }
    }

    // MARK: - References

    var localBranches: [RepositoryBranch] {
        self.branches.filter { !$0.isRemote }
    }

    var remoteBranches: [RepositoryBranch] {
        self.branches.filter(\.isRemote)
    }

    var gitHubRemote: GitRemote? {

        let preferredRemote = self.remotes.first { $0.name == self.upstream?.remoteName && $0.gitHubCoordinate != nil }
        return preferredRemote ?? self.remotes.first { $0.gitHubCoordinate != nil }

    }

    /// Carries references forward when only status was refreshed.
    func replacingStatus(with status: GitRepositorySnapshot) -> GitRepositorySnapshot {

        GitRepositorySnapshot(
            location: status.location,
            head: status.head,
            upstream: status.upstream,
            operation: status.operation,
            changes: status.changes,
            remotes: self.remotes,
            branches: self.branches,
            tags: self.tags,
            recentCommits: self.recentCommits,
            capturedAt: status.capturedAt,
            referencesCapturedAt: self.referencesCapturedAt
        )

    }
}
