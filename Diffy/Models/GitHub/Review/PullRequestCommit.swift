import Foundation

struct PullRequestCommit: Identifiable, Sendable {
    let id: String
    let title: String
    let message: String
    let authorName: String
    let authoredAt: Date
    let parentIDs: [String]

    var shortID: String { String(self.id.prefix(7)) }
}
