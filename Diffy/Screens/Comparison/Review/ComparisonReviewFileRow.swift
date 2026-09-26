import SwiftUI

struct ComparisonReviewFileRow: View {

    @ObservedObject var viewModel: ComparisonReviewFileViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    let presentation: TextDiffPresentation
    let annotate: (AnnotationDraft) -> Void
    let navigateToLine: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            fileHeader()

            if self.viewModel.isExpanded {

                ComparisonReviewFileContent(
                    viewModel: self.viewModel,
                    workspace: self.workspace,
                    presentation: self.presentation,
                    annotate: self.annotate,
                    navigateToLine: self.navigateToLine
                )
                .task { await self.viewModel.load() }

            }

        }
        .background(self.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border))

    }

    private func fileHeader() -> some View {

        HStack(spacing: 12) {

            Button { self.viewModel.isExpanded.toggle() } label: {

                HStack(spacing: 10) {

                    Image(systemName: self.viewModel.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(self.theme.secondaryText)
                        .frame(width: 14)
                    DiffFileIcon(file: self.viewModel.file, size: 14)

                    VStack(alignment: .leading, spacing: 4) {

                        Text(self.viewModel.file.path)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .lineLimit(2)
                            .truncationMode(.middle)

                        if let original = self.viewModel.file.originalPath {
                            Text("Previously \(original)")
                                .font(.system(size: 10))
                                .foregroundStyle(self.theme.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                    }
                    Spacer(minLength: 4)

                }
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .help(self.viewModel.file.path)
            .accessibilityLabel("\(self.viewModel.isExpanded ? "Collapse" : "Expand") \(self.viewModel.file.path)")

            DiffyBadge(title: self.viewModel.file.status.rawValue, color: self.viewModel.file.status.color(in: self.theme))
            DiffChangeSummary(counts: self.viewModel.counts)

            Toggle("Viewed", isOn: Binding(
                get: { self.viewModel.isViewed },
                set: { self.viewModel.markViewed($0) }
            ))
            .toggleStyle(.checkbox)
            .font(.system(size: 11))
            .fixedSize()
            .help("Mark This File As Reviewed")
            .accessibilityLabel("Viewed \(self.viewModel.file.path)")

            Menu {

                Button("Copy Relative Path") { ExportController.copy(self.viewModel.file.path) }
                Button(self.viewModel.isExpanded ? "Collapse File" : "Expand File") { self.viewModel.isExpanded.toggle() }

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 18)
            .accessibilityLabel("Actions For \(self.viewModel.file.path)")

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(self.viewModel.isViewed ? self.theme.selection.opacity(0.5) : self.theme.elevated)
        .overlay(alignment: .bottom) {
            if self.viewModel.isExpanded { self.theme.border.frame(height: 1) }
        }

    }

}
