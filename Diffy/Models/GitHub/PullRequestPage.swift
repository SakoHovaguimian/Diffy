import Foundation

struct PullRequestPage: Sendable {
    let pullRequests: [PullRequestSummary]
    let hasMore: Bool
}
