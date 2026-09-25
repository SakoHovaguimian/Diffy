import Foundation

@MainActor
final class MockWorkspaceService: WorkspaceServiceProtocol {

    let defaultBuckets = MockWorkspaceFixtures.buckets
    private var projects = MockWorkspaceFixtures.projects

    func loadLibrary() -> ProjectLibrary {

        ProjectLibrary(
            projects: self.projects,
            defaultFavoriteProjectIDs: ["rune", "obelisk"],
            defaultRecentProjectIDs: ["rune", "obelisk", "grimoire"]
        )

    }

    func saveProjects(_ projects: [RepositoryProject]) throws {
        self.projects = projects
    }

    func makeCheckoutReference(for directoryURL: URL) throws -> LocalCheckoutReference {

        LocalCheckoutReference(
            bookmarkData: nil,
            lastKnownPath: directoryURL.standardizedFileURL.path
        )

    }

}
