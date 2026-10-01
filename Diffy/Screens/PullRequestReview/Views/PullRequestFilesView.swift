import SwiftUI

struct PullRequestFilesView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            PullRequestFilesControls(viewModel: self.viewModel, navigator: self.viewModel.fileNavigator)
            if self.viewModel.reviewFiles.isEmpty {
                DiffyEmptyState(symbol: "doc", title: "No Changed Files", message: "Files returned by GitHub will appear here.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if self.viewModel.experience == .editor {
                fileNavigatorContent()
            } else if self.viewModel.visibleFiles.isEmpty {

                VStack(spacing: 16) {

                    DiffyEmptyState(symbol: "line.3.horizontal.decrease.circle", title: "No Matching Files", message: "Clear the file filter or show viewed files to continue reviewing.")
                    Button("Clear Filters") { self.viewModel.clearFileFilters() }
                        .padding(.bottom, 30)

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                PullRequestReviewFileList(viewModel: self.viewModel, workspace: self.workspace)
            }

        }

    }

    private func fileNavigatorContent() -> some View {

        GeometryReader { geometry in

            HStack(spacing: 0) {

                PullRequestFileNavigator(viewModel: self.viewModel, navigator: self.viewModel.fileNavigator)
                    .frame(width: min(self.viewModel.navigatorWidth, navigatorMaximumWidth(in: geometry.size.width)))
                HorizontalResizeHandle(
                    label: "Drag To Resize Changed Files",
                    leftBackground: self.theme.surface,
                    resizeGesture: navigatorResizeGesture(availableWidth: geometry.size.width)
                )
                selectedFileContent()

            }

        }

    }

    private func navigatorMaximumWidth(in availableWidth: CGFloat) -> CGFloat {
        min(360, max(190, availableWidth - 400))
    }

    private func navigatorResizeGesture(availableWidth: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                self.viewModel.resizeNavigator(by: value.translation.width, maximumWidth: navigatorMaximumWidth(in: availableWidth))
            }
            .onEnded { _ in
                self.viewModel.finishResizingNavigator()
            }

    }

    private func selectedFileContent() -> some View {

        VStack(spacing: 0) {

            if let fileViewModel = self.viewModel.selectedReviewFile {
                fileHeader(fileViewModel.file)
                PullRequestFileContent(fileViewModel: fileViewModel, viewModel: self.viewModel, workspace: self.workspace)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(fileViewModel.id)
            } else {
                DiffyEmptyState(symbol: "doc", title: "No Changed Files", message: "Files returned by GitHub will appear here.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        }
        .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)

    }

    private func fileHeader(_ file: PullRequestReviewFile) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 12) {

                DiffyPathIcon(path: file.filename)
                Text(file.filename).font(.system(size: 12, weight: .semibold, design: .monospaced)).textSelection(.enabled)
                Spacer()
                Toggle("Viewed", isOn: Binding(
                    get: { self.viewModel.viewedPaths.contains(file.id) },
                    set: { self.viewModel.markViewed($0, file: file) }
                ))
                .toggleStyle(.checkbox)

            }
            if let previous = file.previousFilename {
                Text("Renamed From \(previous)").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            }
            ViewThatFits(in: .horizontal) {

                HStack(spacing: 12) {

                    fileSummary(file)
                    Spacer(minLength: 12)
                    fileControls()

                }

                VStack(alignment: .leading, spacing: 10) {

                    fileSummary(file)
                    fileControls()

                }

            }
            .font(.system(size: 11, design: .monospaced))

        }
        .padding(16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func fileSummary(_ file: PullRequestReviewFile) -> some View {

        HStack(spacing: 8) {

            Text("+\(file.additions)").foregroundStyle(self.theme.countColor(for: file.additions, activeColor: self.theme.added))
            Text("−\(file.deletions)").foregroundStyle(self.theme.countColor(for: file.deletions, activeColor: self.theme.removed))
            if let url = file.blobUrl {
                Link("Open File On GitHub", destination: url)
            }

        }
        .fixedSize(horizontal: true, vertical: false)

    }

    private func fileControls() -> some View {

        HStack(spacing: 8) {

            Button { self.viewModel.moveFile(by: -1) } label: { Image(systemName: "chevron.up") }
                .accessibilityLabel("Previous File")
                .help("Previous File")
                .disabled(!self.viewModel.canMoveFile(by: -1))
            Button { self.viewModel.moveFile(by: 1) } label: { Image(systemName: "chevron.down") }
                .accessibilityLabel("Next File")
                .help("Next File")
                .disabled(!self.viewModel.canMoveFile(by: 1))

        }
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)

    }

}
