import Foundation

struct TextDiffVisibilityInput: Equatable {
    let lines: [DiffLine]
    let collapseUnchanged: Bool
    let ignoreComments: Bool
    let contextLines: Int
    let retainedIDs: Set<Int>
}
