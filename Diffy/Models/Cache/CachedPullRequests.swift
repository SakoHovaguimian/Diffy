import Foundation

struct CachedPullRequests: Codable, Hashable, Sendable {
    let pullRequests: [PullRequestSummary]
    let validators: GitHubResourceValidators
    let viewerLogin: String
}
