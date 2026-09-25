import Foundation

/// A whole-file resolution expressed in the user's terms. During a rebase Git's
/// "ours" and "theirs" stages are swapped; services map these roles to stages.
enum GitConflictResolutionChoice: String, Hashable, Sendable {
    case yours
    case theirs
}
