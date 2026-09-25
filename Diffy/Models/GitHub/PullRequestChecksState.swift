import Foundation

enum PullRequestChecksState: String, Codable, Hashable, Sendable {
    case success
    case failure
    case pending
    case neutral
    case unavailable

    var title: String {

        switch self {

        case .success: "Checks Passed"
        case .failure: "Checks Failed"
        case .pending: "Checks Running"
        case .neutral: "No Check Runs"
        case .unavailable: "Checks Unavailable"

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
