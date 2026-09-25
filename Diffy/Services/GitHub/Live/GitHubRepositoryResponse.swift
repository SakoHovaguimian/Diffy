import Foundation

struct GitHubRepositoryResponse: Decodable, Sendable {
    let id: Int
    let name: String
    let owner: GitHubUserSummary
    let `private`: Bool
    let defaultBranch: String
    let description: String?
    let cloneUrl: String
    let sshUrl: String
    let htmlUrl: URL
    let updatedAt: Date?

    func summary(host: String, installationID: Int? = nil) -> GitHubRepositorySummary {

        GitHubRepositorySummary(id: self.id, coordinate: GitHubRepositoryCoordinate(host: host, owner: self.owner.login, name: self.name), isPrivate: self.private, defaultBranch: self.defaultBranch, summary: self.description, httpsCloneURL: self.cloneUrl, sshCloneURL: self.sshUrl, webURL: self.htmlUrl, updatedAt: self.updatedAt, installationID: installationID)

    }
}
