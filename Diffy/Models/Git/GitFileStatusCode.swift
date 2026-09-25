import Foundation

/// One column of Git's porcelain XY status.
enum GitFileStatusCode: String, Codable, Hashable, Sendable {
    case unmodified
    case modified
    case fileTypeChanged
    case added
    case deleted
    case renamed
    case copied
    case unmerged
    case untracked
    case ignored

    var title: String {

        switch self {

        case .unmodified: "Unchanged"
        case .modified: "Modified"
        case .fileTypeChanged: "Type changed"
        case .added: "Added"
        case .deleted: "Deleted"
        case .renamed: "Renamed"
        case .copied: "Copied"
        case .unmerged: "Conflict"
        case .untracked: "Untracked"
        case .ignored: "Ignored"

        }

    }

    var isChange: Bool {
        self != .unmodified && self != .ignored
    }
}
