import SwiftUI

struct PullRequestFileContent: View {

    @ObservedObject var fileViewModel: PullRequestReviewFileViewModel
    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    var embedsInReviewList = false
    var navigateToLine: ((String) -> Void)? = nil
    @EnvironmentObject private var review: ReviewViewModel

    var body: some View {

        VStack(spacing: 0) {

            if self.fileViewModel.file.patch == nil || !self.fileViewModel.file.hasCompletePatch {
                DiffyStatusBanner(message: self.fileViewModel.file.patch == nil
                    ? "GitHub did not provide a text patch for this file (binary, empty, or too large). Open GitHub to inspect it."
                    : "GitHub provided a partial patch. Open GitHub to inspect the complete file.")
                    .padding(16)
            }
            if self.fileViewModel.file.patch != nil {
                TextDiffScreen(
                    file: self.fileViewModel.comparisonFile,
                    workspace: self.workspace,
                    viewModel: self.fileViewModel.textDiff,
                    reviewContext: reviewContext(),
                    navigateToLine: self.navigateToLine
                )
            } else {
                PullRequestFileDiscussion(viewModel: self.viewModel, drafts: [], comments: unanchoredComments())
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }

        }

    }

    private func unanchoredComments() -> [PullRequestConversationEntry] {
        self.viewModel.unanchoredComments(in: self.fileViewModel.file, lines: self.fileViewModel.lines)
    }

    private func reviewContext() -> TextDiffReviewContext {

        let file = self.fileViewModel.file
        let summary = self.viewModel.details?.summary
        let annotations = self.viewModel.matchingAnnotations(in: self.review.annotations)

        return TextDiffReviewContext(
            leftLabel: summary.map { String($0.baseSHA.prefix(7)) } ?? "Base",
            rightLabel: summary.map { String($0.headSHA.prefix(7)) } ?? "Head",
            layout: self.$viewModel.isUnified,
            visibleDiscussionLineIDs: self.viewModel.discussionLineIDs(in: file, lines: self.fileViewModel.lines),
            canComment: self.viewModel.canReview,
            comment: { line, side in

                if line.status == .identical, let number = line.newNumber {
                    self.viewModel.beginComment(in: file, line: number, side: "RIGHT")
                    return
                }

                guard let number = side == .left ? line.oldNumber : line.newNumber else { return }
                self.viewModel.beginComment(in: file, line: number, side: side.rawValue.uppercased())

            },
            note: { line, side in

                guard let number = side == .left ? line.oldNumber : line.newNumber else { return }
                let snippet = side == .left ? line.left ?? "" : line.right ?? ""
                self.viewModel.beginNote(in: file, line: number, side: side.rawValue.uppercased(), snippet: snippet)

            },
            hasAnnotation: { line, side in

                guard let number = side == .left ? line.oldNumber : line.newNumber else { return false }
                let path = side == .left ? file.previousFilename ?? file.filename : file.filename
                return annotations.contains { $0.filePath == path && $0.side == side && ($0.startLine...$0.endLine).contains(number) }

            },
            lineDiscussion: { line in

                AnyView(PullRequestFileDiscussion(
                    viewModel: self.viewModel,
                    drafts: self.viewModel.drafts(at: line, in: file),
                    comments: self.viewModel.comments(at: line, in: file)
                ))

            },
            fileDiscussion: {
                AnyView(PullRequestFileDiscussion(viewModel: self.viewModel, drafts: [], comments: unanchoredComments()))
            },
            embedsInReviewList: self.embedsInReviewList
        )

    }

}
