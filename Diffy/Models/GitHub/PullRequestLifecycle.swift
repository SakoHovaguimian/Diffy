import SwiftUI

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

    func color(in theme: DiffyTheme, isDraft: Bool = false) -> Color {

        switch self {

        case .open: isDraft ? theme.secondaryText : theme.added
        case .closedUnmerged: theme.secondaryText
        case .merged: theme.changed

        }

    }
}
