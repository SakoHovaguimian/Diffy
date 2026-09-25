import Foundation

struct PullRequestConversationEntry: Identifiable, Sendable {

    enum Kind: String, Sendable {
        case comment
        case review
        case inline
    }

    let remoteID: Int
    let kind: Kind
    let author: String
    let body: String
    let date: Date?
    let webURL: URL?
    let state: String?
    let path: String?
    let line: Int?
    let side: String?
    let replyToID: Int?

    var id: String { "\(self.kind.rawValue)-\(self.remoteID)" }
    var isPending: Bool { self.state == "PENDING" }
    var isOutdated: Bool { self.kind == .inline && self.line == nil }

    var title: String {

        switch self.state {

        case "APPROVED": "Approved"
        case "CHANGES_REQUESTED": "Requested Changes"
        case "DISMISSED": "Review Dismissed"
        case "PENDING": "Pending Review On GitHub"
        default: self.kind == .inline ? "Inline Comment" : "Commented"

        }

    }
}
