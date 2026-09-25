import Foundation

enum PullRequestLifecycle: String, Codable, Hashable, Sendable {
    case open
    case closedUnmerged
    case merged

    var title: String {

        switch self {

        case .open: "Open"
        case .closedUnmerged: "Closed · Unmerged"
        case .merged: "Merged"

        }

    }
}
