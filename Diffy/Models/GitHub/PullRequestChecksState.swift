import Foundation

enum PullRequestChecksState: String, Codable, Hashable, Sendable {
    case success
    case failure
    case pending
    case neutral
    case unavailable

    var title: String {

        switch self {

        case .success: "Checks passed"
        case .failure: "Checks failed"
        case .pending: "Checks running"
        case .neutral: "No check runs"
        case .unavailable: "Checks unavailable"

        }

    }

    var symbol: String {

        switch self {

        case .success: "checkmark.circle.fill"
        case .failure: "xmark.octagon.fill"
        case .pending: "clock.fill"
        case .neutral: "minus.circle"
        case .unavailable: "questionmark.circle"

        }

    }
}
