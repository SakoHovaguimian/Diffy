import Foundation

struct PullRequestReviewRequest: Sendable {
    let number: Int
    let title: String
    let webURL: URL
    let link: GitHubRepositoryLink
    let preferredAccountID: String?
}
