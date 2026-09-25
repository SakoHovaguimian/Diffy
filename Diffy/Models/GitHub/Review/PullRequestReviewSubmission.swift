import Foundation

struct PullRequestReviewSubmission: Encodable, Sendable {
    let commitID: String
    let body: String
    let event: PullRequestReviewEvent
    let comments: [PullRequestReviewCommentDraft]

    enum CodingKeys: String, CodingKey {
        case commitID = "commit_id"
        case body, event, comments
    }
}
