import SwiftUI

struct ComparisonReviewScreen: View {

    @StateObject var viewModel: ComparisonReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {

        VStack(spacing: 0) {

            header()
            controls()
            reviewContent()

        }
        .frame(minWidth: 720, idealWidth: 1440, maxWidth: .infinity, minHeight: 480, idealHeight: 900, maxHeight: .infinity)
        .background(self.theme.background)
        .background(ComparisonModalSizingView())
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
            .help("Close comparison · Escape")

        }
        .padding(24)
        .background(self.theme.surface)

    }

    private func controls() -> some View {

        VStack(spacing: 16) {

            HStack(spacing: 16) {

                Label("\(self.viewModel.files.count.formatted()) changed files", systemImage: "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                DiffChangeSummary(counts: self.viewModel.counts)
                if self.viewModel.hasUnavailableLineCounts {
                    Text("Line totals exclude files without text counts")
                        .font(.system(size: 10))
                        .foregroundStyle(self.theme.secondaryText)
                }
                Spacer()
                Text("\(self.viewModel.viewedCount) of \(self.viewModel.files.count) viewed")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

                Picker("Diff layout", selection: self.$settings.editor.unified) {

                    Text("Split").tag(false)
                    Text("Unified").tag(true)

                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)

            }
            HStack(spacing: 14) {

                HStack(spacing: 8) {

                    Image(systemName: "magnifyingglass").foregroundStyle(self.theme.secondaryText)
                    TextField("Filter changed files…", text: self.$viewModel.query)
                        .textFieldStyle(.plain)
                        .focused(self.$searchFocused)

                    if !self.viewModel.query.isEmpty {

                        Button {

                            self.viewModel.query = ""
                            self.searchFocused = true

                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear file filter")

                    }

                }
                .padding(8)
                .frame(maxWidth: 350)
                .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 6))
                Toggle("Unviewed only", isOn: self.$viewModel.onlyUnviewed)
                    .toggleStyle(.checkbox)
                Spacer()
                Button("Expand shown") { self.viewModel.expandShown() }
                Button("Collapse all") { self.viewModel.collapseAll() }

            }
            .font(.system(size: 11))

        }
        .controlSize(.small)
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }
        .disabled(self.viewModel.isLoading)

    }

    @ViewBuilder
    private func reviewContent() -> some View {

        if self.viewModel.isLoading {
            ProgressView("Reading changed files…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = self.viewModel.error ?? self.viewModel.request.warning {

            VStack(spacing: 16) {

                DiffyEmptyState(symbol: "exclamationmark.circle", title: "Change summary unavailable", message: error)
                if self.viewModel.error != nil {
                    Button("Retry comparison") { Task { await self.viewModel.load() } }
                        .padding(.bottom, 30)
                }

            }

        } else if self.viewModel.files.isEmpty {
            DiffyEmptyState(symbol: "checkmark.circle", title: "No file changes", message: self.viewModel.request.emptyMessage)
        } else if self.viewModel.matchingFiles.isEmpty {

            VStack(spacing: 16) {

                DiffyEmptyState(symbol: "line.3.horizontal.decrease.circle", title: "No matching files", message: "Clear the file filter or show viewed files to continue reviewing.")
                Button("Clear filters") { self.viewModel.clearFilters() }
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

                        ForEach(self.viewModel.visibleFiles) { file in

                            ComparisonReviewFileRow(
                                viewModel: file,
                                workspace: self.workspace,
                                presentation: TextDiffPresentation(selection: selection, mode: self.viewModel.request.mode),
                                annotate: { self.viewModel.annotationDraft = $0 },
                                navigateToLine: { proxy.scrollTo($0, anchor: .center) }
                            )
                            .id(file.id)

                        }

                    }

                    if self.viewModel.matchingFiles.count > self.viewModel.visibleLimit {
                        Button("Show more files") { self.viewModel.visibleLimit += 50 }
                            .padding(16)
                    }

                }
                .padding(24)

            }

        }

    }

}

#Preview("Branch review") {

    let workspace = mockResolve(WorkspaceViewModel.self)
    ComparisonReviewScreen(
        viewModel: workspace.repositoryViewModel.reviewViewModel(for: MockPreviewFixtures.comparisonReview(startsExpanded: true)),
        workspace: workspace
    )
    .frame(width: 1280, height: 800)
    .withMockPreviews()

}

#Preview("Pull summary") {

    let workspace = mockResolve(WorkspaceViewModel.self)
    ComparisonReviewScreen(
        viewModel: workspace.repositoryViewModel.reviewViewModel(for: MockPreviewFixtures.comparisonReview(startsExpanded: false)),
        workspace: workspace
    )
    .frame(width: 1080, height: 700)
    .withMockPreviews()

}
