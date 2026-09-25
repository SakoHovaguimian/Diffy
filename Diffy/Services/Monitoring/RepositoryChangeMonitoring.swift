import Foundation

/// Watches a repository's working tree and Git directory and reports debounced,
/// coalesced changes. Implementations never poll.
@MainActor
protocol RepositoryChangeMonitoring: AnyObject {

    var monitoredProjectIDs: Set<String> { get }

    func startMonitoring(
        _ repository: GitRepositoryReference,
        location: GitRepositoryLocation,
        onChange: @escaping @MainActor (RepositoryChangeEvent) -> Void
    )

    func stopMonitoring(projectID: String)

}
