import Foundation

enum PullRequestFilter: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case all
    case authoredByMe
    case assignedToMe
    case reviewRequested
    case notAssignedToMe

    var id: String {
        self.rawValue
    }

    var title: String {

        switch self {

        case .all: "Anyone"
        case .authoredByMe: "Authored by me"
        case .assignedToMe: "Assigned to me"
        case .reviewRequested: "Review requested"
        case .notAssignedToMe: "Not assigned to me"

        }

    }

    var symbol: String {

        switch self {

        case .all: "tray.full"
        case .authoredByMe: "person"
        case .assignedToMe: "person.crop.circle.badge.checkmark"
        case .reviewRequested: "eye"
        case .notAssignedToMe: "person.crop.circle.badge.xmark"

        }

    }

    func matches(_ pullRequest: PullRequestSummary, viewerLogin: String) -> Bool {

        switch self {

        case .all: true
        case .authoredByMe: pullRequest.isAuthored(by: viewerLogin)
        case .assignedToMe: pullRequest.isAssigned(to: viewerLogin)
        case .reviewRequested: pullRequest.requestsReview(from: viewerLogin)
        case .notAssignedToMe: !pullRequest.isAssigned(to: viewerLogin)

        }

    }
}
