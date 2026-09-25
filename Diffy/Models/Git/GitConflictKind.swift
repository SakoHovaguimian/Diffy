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

        case .bothModified: "Both modified"
        case .bothAdded: "Both added"
        case .bothDeleted: "Both deleted"
        case .addedByUs: "Added by us"
        case .addedByThem: "Added by them"
        case .deletedByUs: "Deleted by us"
        case .deletedByThem: "Deleted by them"

        }

    }
}
