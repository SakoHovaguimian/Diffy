import SwiftUI

struct RepositoryComparisonContent: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var viewModel: RepositoryComparisonViewModel

    var body: some View {

        Group {

            if let error = self.viewModel.listingError ?? self.viewModel.fileError {

                VStack(spacing: 12) {

                    DiffyEmptyState(symbol: "exclamationmark.circle", title: "Comparison Unavailable", message: error)
                    Button("Retry") { self.viewModel.retry() }
                        .padding(.bottom, 24)

                }

            } else if self.viewModel.isLoadingFiles || self.viewModel.isLoadingFile {
                DiffyLoadingState(title: "Reading Comparison…")
            } else if let file = self.viewModel.selectedFile {
                fileContent(file)
            } else {
                DiffyEmptyState(symbol: "checkmark.circle", title: "No Differences", message: "This comparison has no changed files.")
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

    @ViewBuilder
    private func fileContent(_ file: DiffFile) -> some View {

        switch file.kind {

        case .text:
            TextDiffScreen(file: file, workspace: self.workspace, viewModel: self.workspace.textDiffViewModel)
                .id(file.id)

        case .image:
            ImageComparisonScreen(file: file, sources: self.viewModel.imageSources)
                .id(file.id)

        case .binary:
            DiffyEmptyState(symbol: "doc.zipper", title: "Binary File", message: "\(file.path) has no text representation to compare.")

        }

    }

}
