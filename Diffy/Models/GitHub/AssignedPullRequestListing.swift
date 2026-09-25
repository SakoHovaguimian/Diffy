import Foundation

struct AssignedPullRequestListing: Sendable {
    let requests: [AssignedPullRequestSummary]
    let hasMore: Bool
}
