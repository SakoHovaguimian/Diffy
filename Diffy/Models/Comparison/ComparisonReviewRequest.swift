import Foundation

struct ComparisonReviewRequest: Identifiable {
    let id = UUID()
    let repository: GitRepositoryReference
    let selection: ComparisonSelection?
    let title: String
    let detail: String
    let startsExpanded: Bool
    let mode: ComparisonMode
    var emptyMessage = "There are no file changes between these sources."
    var warning: String?
}
