import SwiftUI

struct ComparisonReviewScreen: View {

    @StateObject var viewModel: ComparisonReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(spacing: 0) {

            header()
            ComparisonReviewControls(viewModel: self.viewModel, navigator: self.viewModel.navigator)
            reviewContent()

        }
        .background(self.theme.background)
        .diffyDataModalFrame()
        .task { await self.viewModel.load() }
        .sheet(item: self.$viewModel.annotationDraft) { draft in
            AnnotationEditorScreen(draft: draft, workspace: self.workspace).diffyStyle()
        }

    }

    private func header() -> some View {

        HStack(alignment: .top, spacing: 24) {

            VStack(alignment: .leading, spacing: 7) {

                Text(self.viewModel.request.title)
                    .font(.system(size: 22, weight: .semibold))
                    .textSelection(.enabled)
                Text(self.viewModel.request.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(self.theme.secondaryText)
                    .textSelection(.enabled)
                if let success = self.viewModel.request.successMessage {
                    Label(success, systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(self.theme.added)
                        .padding(.top, 5)
                }

            }
            Spacer(minLength: 12)
            Button { self.dismiss() } label: {
                Label("Close", systemImage: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.cancelAction)
            .help("Close Comparison · Escape")

        }
        .padding(24)
        .background(self.theme.surface)

    }

    @ViewBuilder
    private func reviewContent() -> some View {

        if self.viewModel.isLoading {
            DiffyLoadingState(title: "Reading Changed Files…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = self.viewModel.error ?? self.viewModel.request.warning {

            VStack(spacing: 16) {

                DiffyEmptyState(symbol: "exclamationmark.circle", title: "Change Summary Unavailable", message: error)
                if self.viewModel.error != nil {
                    Button("Retry Comparison") { Task { await self.viewModel.load() } }
                        .padding(.bottom, 30)
                }

            }

        } else if self.viewModel.files.isEmpty {
            DiffyEmptyState(symbol: "checkmark.circle", title: "No File Changes", message: self.viewModel.request.emptyMessage)
        } else if self.viewModel.experience == .editor {
            ComparisonReviewEditor(viewModel: self.viewModel, workspace: self.workspace)
        } else if self.viewModel.matchingFiles.isEmpty {

            VStack(spacing: 16) {

                DiffyEmptyState(symbol: "line.3.horizontal.decrease.circle", title: "No Matching Files", message: "Clear the file filter or show viewed files to continue reviewing.")
                Button("Clear Filters") { self.viewModel.clearFilters() }
                    .padding(.bottom, 30)

            }

        } else {
            fileList()
        }

    }

    private func fileList() -> some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(spacing: 16) {

                    if let selection = self.viewModel.request.selection {

                        ForEach(self.viewModel.reviewEntries) { entry in

                            if let summary = entry.file, let file = self.viewModel.fileViewModel(for: summary.id) {

                                ComparisonReviewFileRow(
                                    viewModel: file,
                                    workspace: self.workspace,
                                    presentation: TextDiffPresentation(selection: selection, mode: self.viewModel.request.mode),
                                    annotate: { self.viewModel.annotationDraft = $0 },
                                    navigateToLine: { proxy.scrollTo($0, anchor: .center) }
                                )
                                .id(file.id)

                            } else if entry.file == nil {
                                FileNavigatorGroupRow(entry: entry, viewModel: self.viewModel.navigator)
                            }

                        }

                    }

                    if self.viewModel.matchingFiles.count > self.viewModel.visibleLimit {
                        Button("Show More Files") { self.viewModel.visibleLimit += 50 }
                            .padding(16)
                    }

                }
                .padding(24)

            }

        }

    }

}

#Preview("Branch Review") {

    let workspace = mockResolve(WorkspaceViewModel.self)
    ComparisonReviewScreen(
        viewModel: workspace.repositoryViewModel.reviewViewModel(for: MockPreviewFixtures.comparisonReview(startsExpanded: true)),
        workspace: workspace
    )
    .frame(width: 1280, height: 800)
    .withMockPreviews()

}

#Preview("Pull Summary") {

    let workspace = mockResolve(WorkspaceViewModel.self)
    ComparisonReviewScreen(
        viewModel: workspace.repositoryViewModel.reviewViewModel(for: MockPreviewFixtures.comparisonReview(startsExpanded: false)),
        workspace: workspace
    )
    .frame(width: 1080, height: 700)
    .withMockPreviews()

}
