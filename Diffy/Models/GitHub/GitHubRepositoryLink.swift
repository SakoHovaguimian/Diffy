import Foundation

/// An optional association between a Diffy project and a GitHub repository.
/// Local Git features never depend on it.
struct GitHubRepositoryLink: Codable, Hashable, Sendable {
    let coordinate: GitHubRepositoryCoordinate
    var repositoryID: Int?
    var remoteName: String?

    var host: String {
        self.coordinate.host
    }

    var fullName: String {
        self.coordinate.fullName
    }

    var webURL: URL? {
        URL(string: "https://\(self.coordinate.host)/\(self.coordinate.fullName)")
    }
}
