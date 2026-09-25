import Foundation

/// A debounced, coalesced burst of filesystem activity for one repository.
struct RepositoryChangeEvent: Hashable, Sendable {
    let projectID: String
    let touchesWorkingTree: Bool

    /// HEAD, refs, the index, or merge/rebase state changed; references need a full refresh.
    let touchesGitMetadata: Bool
}
