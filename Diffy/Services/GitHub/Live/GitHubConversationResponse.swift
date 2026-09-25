import Foundation

/// Shared fields in issue comments, review comments, and submitted reviews.
struct GitHubConversationResponse: Decodable, Sendable {
    let id: Int
    let user: GitHubUserSummary?
    let body: String?
    let createdAt: Date?
    let submittedAt: Date?
    let htmlUrl: URL?
    let state: String?
    let path: String?
    let line: Int?
    let side: String?
    let inReplyToId: Int?

    func entry(kind: PullRequestConversationEntry.Kind) -> PullRequestConversationEntry {

        PullRequestConversationEntry(
            remoteID: self.id,
            kind: kind,
            user: self.user,
            body: self.body ?? "",
            date: self.submittedAt ?? self.createdAt,
            webURL: self.htmlUrl,
            state: self.state,
            path: self.path,
            line: self.line,
            side: self.side,
            replyToID: self.inReplyToId
        )

    }
}
