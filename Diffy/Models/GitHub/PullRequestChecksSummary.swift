import Foundation

struct PullRequestChecksSummary: Codable, Hashable, Sendable {
    let state: PullRequestChecksState
    var total: Int = 0
    var passed: Int = 0
    var failed: Int = 0
    var pending: Int = 0

    static let unavailable = PullRequestChecksSummary(state: .unavailable)
}
