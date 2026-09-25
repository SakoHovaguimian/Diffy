import Foundation

/// The actual source transition captured around a completed Git operation.
struct GitOperationComparison: Hashable, Sendable {
    let selection: ComparisonSelection?
    let title: String
    let detail: String
    let emptyMessage: String
    var warning: String?
}
