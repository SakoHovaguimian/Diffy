import Foundation

struct GitHubRepositorySummary: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let coordinate: GitHubRepositoryCoordinate
    let isPrivate: Bool
    let defaultBranch: String
    var summary: String?
    let httpsCloneURL: String
    let sshCloneURL: String
    let webURL: URL
    var updatedAt: Date?
    var installationID: Int?

    var fullName: String {
        self.coordinate.fullName
    }

    func link(remoteName: String?) -> GitHubRepositoryLink {
        GitHubRepositoryLink(coordinate: self.coordinate, repositoryID: self.id, remoteName: remoteName)
    }
}
