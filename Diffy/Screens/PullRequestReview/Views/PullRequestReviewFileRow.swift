import SwiftUI

struct PullRequestReviewFileRow: View {

    @ObservedObject var fileViewModel: PullRequestReviewFileViewModel
    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    let navigateToLine: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            fileHeader()
            if self.fileViewModel.isExpanded {
                PullRequestFileContent(
                    fileViewModel: self.fileViewModel,
                    viewModel: self.viewModel,
                    workspace: self.workspace,
                    embedsInReviewList: true,
                    navigateToLine: self.navigateToLine
                )
            }

        }
        .background(self.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border))

    }

    private func fileHeader() -> some View {

        let file = self.fileViewModel.file

        return HStack(spacing: 12) {

            Button { self.fileViewModel.isExpanded.toggle() } label: {

                HStack(spacing: 10) {

                    Image(systemName: self.fileViewModel.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(self.theme.secondaryText)
                        .frame(width: 14)
                    DiffFileIcon(file: file.navigationFile, size: 14)
                    VStack(alignment: .leading, spacing: 4) {

                        Text(file.filename)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .lineLimit(2)
                            .truncationMode(.middle)
                        if let previous = file.previousFilename {
                            Text("Previously \(previous)")
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
            .help(file.filename)
            .accessibilityLabel("\(self.fileViewModel.isExpanded ? "Collapse" : "Expand") \(file.filename)")

            DiffyBadge(title: file.navigationFile.status.rawValue, color: file.navigationFile.status.color(in: self.theme))
            DiffChangeSummary(counts: self.fileViewModel.counts)
                .layoutPriority(1)
            Toggle("Viewed", isOn: Binding(
                get: { self.viewModel.viewedPaths.contains(file.id) },
                set: { self.viewModel.markViewed($0, file: file) }
            ))
            .toggleStyle(.checkbox)
            .font(.system(size: 11))
            .fixedSize()
            .help("Mark This File As Reviewed Locally")
            .accessibilityLabel("Viewed \(file.filename)")

            Menu {

                Button("Copy Relative Path") { ExportController.copy(file.filename) }
                if let url = file.blobUrl { Link("Open File On GitHub", destination: url) }
                Button("Open In File Navigator") {

                    self.viewModel.selectFile(file)
                    self.viewModel.experience = .editor

                }

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 40)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("Actions For \(file.filename)")

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(self.viewModel.viewedPaths.contains(file.id) ? self.theme.selection.opacity(0.5) : self.theme.elevated)
        .overlay(alignment: .bottom) {
            if self.fileViewModel.isExpanded { self.theme.border.frame(height: 1) }
        }

    }

}
