import Foundation

struct GitOperationResult: Hashable, Sendable {
    let message: String
    var comparison: GitOperationComparison? = nil

    /// A merge, rebase, or pull paused because files need resolution.
    var stoppedForConflicts: Bool = false
}
