import Foundation

struct PullRequestReviewCommentDraft: Identifiable, Encodable, Sendable {
    var id = UUID()
    let path: String
    let line: Int
    let side: String
    var body: String

    enum CodingKeys: String, CodingKey {
        case path, line, side, body
    }
}
