import Foundation

/// Observes on-disk checkout changes while a live repository is selected.
protocol RepositoryChangeMonitoring: AnyObject {
    func startMonitoring(
        reference: GitRepositoryReference,
        location: GitRepositoryLocation,
        onChange: @escaping @Sendable () -> Void
    ) throws

    func stopMonitoring()
}
