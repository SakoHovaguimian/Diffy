import Foundation

/// A path reported by `git status`. The index and working-tree columns are independent,
/// so one file can have both staged and unstaged changes.
struct GitFileChange: Codable, Hashable, Identifiable, Sendable {
    let path: String
    let originalPath: String?
    let indexStatus: GitFileStatusCode
    let worktreeStatus: GitFileStatusCode
    var conflict: GitConflictKind?
    var lastEditedAt: Date?

    var id: String {
        self.path
    }

    var isConflicted: Bool {
        self.conflict != nil
    }

    var isUntracked: Bool {
        self.worktreeStatus == .untracked
    }

    var hasStagedChanges: Bool {
        !self.isConflicted && !self.isUntracked && self.indexStatus.isChange
    }

    var hasUnstagedChanges: Bool {
        !self.isConflicted && self.worktreeStatus.isChange
    }
}
