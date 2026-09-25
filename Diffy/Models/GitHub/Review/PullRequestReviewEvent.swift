import Foundation

enum PullRequestReviewEvent: String, CaseIterable, Identifiable, Encodable, Sendable {
    case comment = "COMMENT"
    case approve = "APPROVE"
    case requestChanges = "REQUEST_CHANGES"

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .comment: "Comment"
        case .approve: "Approve"
        case .requestChanges: "Request Changes"

        }

    }
}
