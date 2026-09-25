import Foundation

struct PullRequestReviewDetails: Sendable {
    let summary: PullRequestSummary
    let body: String
    let changedFileCount: Int
    let commitCount: Int
    let commits: [PullRequestCommit]
    let files: [PullRequestReviewFile]
    let conversation: [PullRequestConversationEntry]

    var hasAllFiles: Bool { self.files.count == self.changedFileCount }
    var hasAllCommits: Bool { self.commits.count == self.commitCount }
}
