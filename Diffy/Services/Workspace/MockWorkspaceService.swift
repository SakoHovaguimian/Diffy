import Foundation

@MainActor
final class MockWorkspaceService: WorkspaceServiceProtocol {

    let buckets: [Bucket] = MockWorkspaceFixtures.buckets
    let projects: [RepositoryProject] = MockWorkspaceFixtures.projects

}
