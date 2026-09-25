import Foundation

/// An open pull request assigned to a connected user across visible repositories.
struct AssignedPullRequestSummary: Hashable, Identifiable, Sendable {
    let number: Int
    let title: String
    let author: GitHubUserSummary
    let repositoryFullName: String
    let updatedAt: Date
    let webURL: URL

    var id: String {
        self.webURL.absoluteString
    }
}
