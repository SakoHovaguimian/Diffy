import Foundation

struct GitHubAssignedPullRequestSearchResponse: Decodable, Sendable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [GitHubAssignedPullRequestResponse]
}

struct GitHubAssignedPullRequestResponse: Decodable, Sendable {
    let number: Int
    let title: String
    let user: GitHubUserSummary
    let repositoryUrl: URL
    let updatedAt: Date
    let htmlUrl: URL

    var summary: AssignedPullRequestSummary {

        let repositoryName = self.repositoryUrl.pathComponents.suffix(2).joined(separator: "/")

        return AssignedPullRequestSummary(
            number: self.number,
            title: self.title,
            author: self.user,
            repositoryFullName: repositoryName,
            updatedAt: self.updatedAt,
            webURL: self.htmlUrl
        )

    }
}
