import Foundation

/// A conflicted file read from Git's index stages (1 base, 2 ours, 3 theirs), expressed
/// in the user's roles. During a rebase "yours" is the commit being replayed.
struct GitConflictDocument: Hashable, Sendable {
    let path: String
    let kind: GitConflictKind
    let operation: GitOperationState
    let baseLabel: String
    let yoursLabel: String
    let theirsLabel: String
    let segments: [MergeDocumentSegment]
    let isBinary: Bool
    var baseSize: Int?
    var yoursSize: Int?
    var theirsSize: Int?

    /// Identifies the stage contents so a saved draft is only restored for the same sources.
    let fingerprint: String

    var conflicts: [MergeConflict] {

        self.segments.compactMap { segment in

            if case let .conflict(conflict) = segment {
                return conflict
            }

            return nil

        }

    }
}
