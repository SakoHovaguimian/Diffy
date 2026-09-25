import SwiftUI

struct ComparisonScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            if [.branches, .commits, .history].contains(self.workspace.mode) {
                ComparisonSourceBar(workspace: self.workspace)
            }

            HSplitView {

                FileNavigatorScreen(workspace: self.workspace, viewModel: self.workspace.fileNavigatorViewModel)
                    .frame(minWidth: 205, idealWidth: 245, maxWidth: 380)

                comparisonContent()
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)

            }

        }

    }

    @ViewBuilder
    private func comparisonContent() -> some View {

        if self.workspace.mode == .merge {
            MergeScreen(workspace: self.workspace, viewModel: MergeViewModel())
        } else if let file = self.workspace.file {

            switch file.kind {

            case .text:
                TextDiffScreen(
                    file: file,
                    workspace: self.workspace,
                    viewModel: self.workspace.makeTextDiffViewModel()
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
