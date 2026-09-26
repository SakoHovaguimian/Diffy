import SwiftUI

struct ComparisonReviewFileContent: View {

    @ObservedObject var viewModel: ComparisonReviewFileViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    let presentation: TextDiffPresentation
    let annotate: (AnnotationDraft) -> Void
    var navigateToLine: ((String) -> Void)? = nil

    @ViewBuilder
    var body: some View {

        if let error = self.viewModel.error {

            VStack(spacing: 12) {

                DiffyStatusBanner(message: error, isError: true)
                Button("Retry File") { Task { await self.viewModel.load() } }

            }
            .padding(24)

        } else if self.viewModel.isLoading || !self.viewModel.file.isContentLoaded {
            DiffyLoadingState(title: "Reading File…")
                .frame(maxWidth: .infinity)
                .frame(height: 150)
        } else {

            switch self.viewModel.file.kind {

            case .text:
                TextDiffScreen(
                    file: self.viewModel.file,
                    workspace: self.workspace,
                    viewModel: self.viewModel.textDiff,
                    presentation: self.presentation,
                    annotate: self.annotate,
                    navigateToLine: self.navigateToLine
                )

            case .image:
                ImageComparisonScreen(file: self.viewModel.file, sources: self.workspace.runtime.isLive ? self.viewModel.images : nil)
                    .frame(minHeight: 320, idealHeight: 520, maxHeight: self.presentation.embedsInReviewList ? 520 : .infinity)

            case .binary:
                DiffyEmptyState(symbol: "doc.zipper", title: "Binary File", message: "This file changed, but has no text representation to compare.")
                    .frame(height: 160)

            }

        }

    }

}
