import Foundation

@MainActor
protocol WorkspaceServiceProtocol {

    var buckets: [Bucket] { get }
    var projects: [RepositoryProject] { get }

}
