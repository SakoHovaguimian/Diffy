import Foundation

/// Runtime repository state for one project. The snapshot is the last successful read;
/// a failed refresh keeps it and records the failure instead of clearing it.
struct RepositoryState: Hashable {

    var availability: CheckoutAvailability = .unknown
    var snapshot: GitRepositorySnapshot?
    var freshness: CacheFreshness = .none
    var isRefreshing = false
    var refreshFailure: String?
    var refreshRevision = 0
    var suggestedPullStrategy: GitPullStrategy = .fastForwardOnly

    var isLoadingFirstSnapshot: Bool {
        self.snapshot == nil && self.isRefreshing
    }

}
