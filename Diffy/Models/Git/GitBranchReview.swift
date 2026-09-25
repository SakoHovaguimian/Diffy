import Foundation

struct GitBranchReview: Sendable {
    let selection: ComparisonSelection?
    let detail: String
    let emptyMessage: String
}
