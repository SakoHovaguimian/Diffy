import Foundation

struct PullRequestHistoricalFileSelection {
    let file: AIFileSnapshot
    let createdAt: Date
    let headSHA: String
    let isCurrentRevision: Bool
}
