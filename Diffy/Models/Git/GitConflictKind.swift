import Foundation

enum GitConflictKind: String, Codable, Hashable, Sendable {
    case bothModified
    case bothAdded
    case bothDeleted
    case addedByUs
    case addedByThem
    case deletedByUs
    case deletedByThem

    var title: String {

        switch self {

        case .bothModified: "Both Modified"
        case .bothAdded: "Both Added"
        case .bothDeleted: "Both Deleted"
        case .addedByUs: "Added By Us"
        case .addedByThem: "Added By Them"
        case .deletedByUs: "Deleted By Us"
        case .deletedByThem: "Deleted By Them"

        }

    }
}
