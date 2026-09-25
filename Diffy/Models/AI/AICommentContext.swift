import Foundation

/// A complete PR discussion entry, separate from Diffy's own AI conversation history.
struct AICommentContext: Codable, Hashable, Sendable {

    let id: String
    let remoteID: Int
    let kind: String
    let author: String
    let body: String
    let date: String?
    let webURL: String?
    let state: String?
    let path: String?
    let line: Int?
    let side: String?
    let replyToID: Int?
    let isPending: Bool
    let isOutdated: Bool

    init(entry: PullRequestConversationEntry) {

        self.id = entry.id
        self.remoteID = entry.remoteID
        self.kind = entry.kind.rawValue
        self.author = entry.author
        self.body = entry.body
        self.date = entry.date?.ISO8601Format()
        self.webURL = entry.webURL?.absoluteString
        self.state = entry.state
        self.path = entry.path
        self.line = entry.line
        self.side = entry.side
        self.replyToID = entry.replyToID
        self.isPending = entry.isPending
        self.isOutdated = entry.isOutdated

    }

}
