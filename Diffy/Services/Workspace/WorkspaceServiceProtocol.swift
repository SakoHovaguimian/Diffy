import Foundation

/// Project records and default organization for the current runtime.
@MainActor
protocol WorkspaceServiceProtocol: AnyObject {

    var defaultBuckets: [Bucket] { get }

    func loadLibrary() -> ProjectLibrary

    /// Persists project records. Implementations never overwrite a store they could not read.
    func saveProjects(_ projects: [RepositoryProject]) throws

    /// Creates a reference that can reopen a user-selected folder across launches.
    func makeCheckoutReference(for directoryURL: URL) throws -> LocalCheckoutReference

}
