import SwiftUI

enum FileChangeStatus: String, CaseIterable, Codable, Identifiable, Sendable {

    case modified = "Modified"
    case added = "Added"
    case removed = "Removed"
    case renamed = "Renamed"
    case moved = "Moved"
    case identical = "Identical"
    case conflicted = "Conflicted"

    var id: String { self.rawValue }

    var symbol: String {

        switch self {

        case .modified: "circle.lefthalf.filled"
        case .added: "plus"
        case .removed: "minus"
        case .renamed: "arrow.turn.down.right"
        case .moved: "arrow.right"
        case .identical: "equal"
        case .conflicted: "exclamationmark.triangle.fill"

        }

    }

    func color(in theme: DiffyTheme) -> Color {

        switch self {

        case .added: theme.added
        case .removed: theme.removed
        case .modified, .conflicted: theme.modified
        case .renamed, .moved: theme.accent
        case .identical: theme.secondaryText

        }

    }

}
