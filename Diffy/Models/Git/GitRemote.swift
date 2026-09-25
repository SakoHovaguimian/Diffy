import Foundation

/// A configured remote. URLs are stored without user-info so credentials never reach
/// the cache, logs, or the interface.
struct GitRemote: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let fetchURL: String
    let pushURL: String

    var id: String {
        self.name
    }

    var gitHubCoordinate: GitHubRepositoryCoordinate? {
        GitHubRepositoryCoordinate(remoteURL: self.fetchURL)
    }
}
