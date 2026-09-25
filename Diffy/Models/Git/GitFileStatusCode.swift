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

    var isChange: Bool {
        self != .unmodified && self != .ignored
    }
}
