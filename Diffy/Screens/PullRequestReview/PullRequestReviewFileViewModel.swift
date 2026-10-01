import Foundation
import Combine

@MainActor
final class PullRequestReviewFileViewModel: ViewModel, Identifiable {

    let loggerName = "PULL_REQUEST_REVIEW_FILE_VIEW_MODEL"
    let id: String
    let file: PullRequestReviewFile
    let textDiff: TextDiffViewModel
    @Published var isExpanded: Bool

    lazy var lines: [DiffLine] = self.file.patch.map(GitPatchParser.lines) ?? []
    lazy var comparisonFile: DiffFile = self.file.navigationFile.replacingContent(lines: self.lines, kind: .text)

    var counts: DiffLineCounts {
        DiffLineCounts(additions: self.file.additions, deletions: self.file.deletions)
    }

    init(
        file: PullRequestReviewFile,
        diffBuilder: TextDiffBuilding,
        isExpanded: Bool = false
    ) {

        self.id = file.id
        self.file = file
        self.textDiff = TextDiffViewModel(diffBuilder: diffBuilder)
        self.isExpanded = isExpanded

    }

}
