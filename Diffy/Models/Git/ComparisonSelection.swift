import Foundation

struct ComparisonSelection: Codable, Hashable, Sendable {
    let left: ComparisonSource
    let right: ComparisonSource

    /// Compares `right` with the merge base of both sides, as a pull request does.
    var usesMergeBase: Bool = false

    /// Restricts the comparison to specific repository-relative paths.
    var paths: [String] = []

    static let workingTree = ComparisonSelection(left: .index, right: .workingTree)
    static let staged = ComparisonSelection(left: .head, right: .index)

    static func commit(_ commitID: String) -> ComparisonSelection {
        ComparisonSelection(left: .parent(of: commitID), right: .revision(commitID))
    }

    var displayTitle: String {

        let separator = self.usesMergeBase ? " ⋯ " : " → "
        return self.left.displayLabel + separator + self.right.displayLabel

    }

    /// Retain the original spelling used to match saved annotations.
    var title: String {

        let separator = self.usesMergeBase ? " ⋯ " : " → "
        return self.left.label + separator + self.right.label

    }

    /// A filesystem-safe key for cached listings of this selection.
    var cacheKey: String {

        let components = [self.left.label, self.right.label, self.usesMergeBase ? "merge-base" : "direct"] + self.paths
        let joined = components.joined(separator: "|")

        return String(joined.map { $0.isLetter || $0.isNumber ? $0 : "-" })

    }
}
