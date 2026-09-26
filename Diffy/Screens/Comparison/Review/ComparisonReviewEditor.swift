import SwiftUI

struct ComparisonReviewEditor: View {

    @ObservedObject var viewModel: ComparisonReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel

    var body: some View {

        GeometryReader { geometry in

            HStack(spacing: 0) {

                FileNavigatorView(
                    files: self.viewModel.navigationFiles,
                    mode: self.viewModel.request.mode,
                    selectedFileID: self.viewModel.selectedFile?.id,
                    isLoading: self.viewModel.isLoading,
                    isLive: self.workspace.runtime.isLive,
                    selectFile: self.viewModel.selectFile,
                    viewModel: self.viewModel.navigator
                )
                .frame(width: min(self.viewModel.navigatorWidth, navigatorMaximumWidth(in: geometry.size.width)))
                HorizontalResizeHandle(
                    label: "Drag To Resize Changed Files",
                    resizeGesture: navigatorResizeGesture(availableWidth: geometry.size.width)
                )
                selectedFileContent()
                    .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)

            }

        }

    }

    @ViewBuilder
    private func selectedFileContent() -> some View {

        if let file = self.viewModel.selectedFile, let selection = self.viewModel.request.selection {

            ComparisonReviewSelectedFile(
                viewModel: file,
                workspace: self.workspace,
                presentation: TextDiffPresentation(selection: selection, mode: self.viewModel.request.mode, embedsInReviewList: false),
                annotate: { self.viewModel.annotationDraft = $0 }
            )
            .id(file.id)

        } else {
            DiffyEmptyState(symbol: "doc.text.magnifyingglass", title: "Choose A File", message: "Select a file in the navigator to explore its changes. Clear filters if the file you want is hidden.")
        }

    }

    private func navigatorMaximumWidth(in availableWidth: CGFloat) -> CGFloat {
        min(380, max(205, availableWidth - 400))
    }

    private func navigatorResizeGesture(availableWidth: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                self.viewModel.resizeNavigator(by: value.translation.width, maximumWidth: navigatorMaximumWidth(in: availableWidth))
            }
            .onEnded { _ in self.viewModel.finishResizingNavigator() }

    }

}
