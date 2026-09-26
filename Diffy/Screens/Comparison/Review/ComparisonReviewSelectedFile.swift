import SwiftUI

struct ComparisonReviewSelectedFile: View {

    @ObservedObject var viewModel: ComparisonReviewFileViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    let presentation: TextDiffPresentation
    let annotate: (AnnotationDraft) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            header()
            ComparisonReviewFileContent(
                viewModel: self.viewModel,
                workspace: self.workspace,
                presentation: self.presentation,
                annotate: self.annotate
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
        .task { await self.viewModel.load() }

    }

    private func header() -> some View {

        HStack(spacing: 12) {

            DiffFileIcon(file: self.viewModel.file, size: 14)
            Text(self.viewModel.file.path)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(self.viewModel.file.path)
            Spacer(minLength: 4)
            DiffChangeSummary(counts: self.viewModel.counts)
            Toggle("Viewed", isOn: Binding(
                get: { self.viewModel.isViewed },
                set: { self.viewModel.markViewed($0) }
            ))
            .toggleStyle(.checkbox)
            .font(.system(size: 11))

        }
        .padding(16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

}
