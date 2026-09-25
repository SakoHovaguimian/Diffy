import SwiftUI

struct ComparisonScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @State private var navigatorWidth: CGFloat = 245
    @State private var navigatorDragStartWidth: CGFloat?

    var body: some View {

        VStack(spacing: 0) {

            if !self.workspace.runtime.isLive && [.branches, .commits, .history].contains(self.workspace.mode) {
                ComparisonSourceBar(workspace: self.workspace)
            }

            HStack(spacing: 0) {

                FileNavigatorScreen(workspace: self.workspace, viewModel: self.workspace.fileNavigatorViewModel)
                    .frame(width: self.navigatorWidth)

                HorizontalResizeHandle(label: "Drag to resize changed files", resizeGesture: navigatorResizeGesture())

                comparisonContent()
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)

            }

        }

    }

    private func navigatorResizeGesture() -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in

                if self.navigatorDragStartWidth == nil {
                    self.navigatorDragStartWidth = self.navigatorWidth
                }

                let startingWidth = self.navigatorDragStartWidth ?? self.navigatorWidth
                self.navigatorWidth = min(380, max(205, startingWidth + value.translation.width))

            }
            .onEnded { _ in
                self.navigatorDragStartWidth = nil
            }

    }

    @ViewBuilder
    private func comparisonContent() -> some View {

        if self.workspace.runtime.isLive {
            RepositoryComparisonContent(workspace: self.workspace, viewModel: self.workspace.repositoryViewModel.comparison)
        } else if self.workspace.mode == .merge {
            MergeScreen(workspace: self.workspace, viewModel: MergeViewModel())
        } else if let file = self.workspace.file {

            switch file.kind {

            case .text:
                TextDiffScreen(
                    file: file,
                    workspace: self.workspace,
                    viewModel: self.workspace.textDiffViewModel
                )
                    .id(file.id)

            case .image:
                ImageComparisonScreen(file: file)
                    .id(file.id)

            case .binary:
                DiffyEmptyState(
                    symbol: "doc.zipper",
                    title: "A little beyond plain text",
                    message: "\(file.name) is a binary file. The sample metadata reports \(file.size.formatted()) bytes. A textual comparison is unavailable."
                )

            }

        } else {

            DiffyEmptyState(symbol: "doc.text.magnifyingglass", title: "Choose a file", message: "Select a file in the navigator to explore its changes.")

        }

    }

}

#Preview {

    ComparisonScreen(
        workspace: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 1050, height: 680)
    .withMockPreviews()

}
