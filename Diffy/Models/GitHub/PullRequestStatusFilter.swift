import Foundation

enum PullRequestStatusFilter: String, CaseIterable, Identifiable {
    case unmerged
    case open
    case draft
    case closedUnmerged

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .unmerged: "Unmerged"
        case .open: "Open · ready"
        case .draft: "Draft"
        case .closedUnmerged: "Closed · unmerged"

        }

    }

    func matches(_ request: PullRequestSummary) -> Bool {

        switch self {

        case .unmerged: request.lifecycle != .merged
        case .open: request.lifecycle == .open && !request.isDraft
        case .draft: request.lifecycle == .open && request.isDraft
        case .closedUnmerged: request.lifecycle == .closedUnmerged

        }

    }
}
