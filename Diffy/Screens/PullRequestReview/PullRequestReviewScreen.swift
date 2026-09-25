import SwiftUI

struct PullRequestReviewScreen: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var aiWorkspace: AIReviewWorkspaceViewModel
    @ObservedObject var patchReview: AIReviewPatchViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme

    private var matchingNotes: [CodeAnnotation] {
        self.viewModel.matchingAnnotations(in: self.review.annotations)
    }

    private var isShowingAIContent: Bool {
        self.viewModel.selectedTab.visualization != nil
            || self.viewModel.selectedTab == .aiNotes
            || self.viewModel.historicalFileSelection != nil
    }

    var body: some View {

        VStack(spacing: 0) {

            PullRequestReviewHeaderView(viewModel: self.viewModel, aiWorkspace: self.aiWorkspace) {
                self.workspace.closePullRequest()
            }
            PullRequestReviewNavigationView(
                viewModel: self.viewModel,
                aiWorkspace: self.aiWorkspace,
                notesCount: self.matchingNotes.count
            )
            messages()
            if self.viewModel.showsNotes {
                PullRequestReviewNotesView(
                    viewModel: self.viewModel,
                    aiWorkspace: self.aiWorkspace,
                    notes: self.matchingNotes
                )
            }
            content()

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(self.theme.background)
        .task { await self.viewModel.loadIfNeeded() }
        .task { await self.aiWorkspace.loadHistory() }
        .task { syncAnnotations() }
        .onChange(of: self.review.annotations) { _, _ in syncAnnotations() }
        .onChange(of: self.viewModel.noteSource) { _, _ in syncAnnotations() }
        .onChange(of: self.aiWorkspace.requestedVisualization) { _, requested in

            guard let requested else { return }
            self.viewModel.selectedTab = tab(for: requested)
            self.aiWorkspace.consumeRequestedVisualization()

        }
        .onChange(of: self.aiWorkspace.proposedFixEntry?.id) { _, proposedID in
            if proposedID != nil && self.aiWorkspace.isAddressingNotes { self.viewModel.selectedTab = .aiNotes }
        }
        .onChange(of: self.patchReview.notice) { _, notice in
            if notice != nil { Task { await self.workspace.repositoryViewModel.refresh() } }
        }
        .sheet(isPresented: self.$viewModel.showsReviewComposer) {
            PullRequestSubmitReviewView(viewModel: self.viewModel).diffyStyle()
        }
        .sheet(item: self.$viewModel.commentEditor) { draft in
            PullRequestCommentEditor(draft: draft, save: self.viewModel.saveComment).diffyStyle()
        }
        .sheet(item: self.$viewModel.noteDraft) { draft in

            PullRequestNoteEditor(draft: draft) { comment in
                self.review.add(self.viewModel.annotation(from: draft, comment: comment))
                self.viewModel.noteDraft = nil
            }
            .diffyStyle()

        }
        .confirmationDialog("Discard Drafts & Refresh?", isPresented: self.$viewModel.showsReloadConfirmation, titleVisibility: .visible) {

            Button("Discard Drafts & Refresh", role: .destructive) {

                self.viewModel.discardDrafts()
                Task { await self.viewModel.load() }

            }
            Button("Keep Drafts", role: .cancel) {}

        } message: {
            Text("Refreshing loads the current revision. Draft line comments cannot be moved safely to changed code.")
        }

    }

    private func messages() -> some View {

        VStack(spacing: 8) {

            if self.aiWorkspace.isBusy {
                DiffyLoadingState(title: self.aiWorkspace.requestProgress ?? "Preparing AI Request…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let error = self.viewModel.errorMessage {
                DiffyStatusBanner(message: error, isError: true)
            }
            if let notice = self.viewModel.notice {
                DiffyStatusBanner(message: notice)
            }
            if self.viewModel.hasPendingRemoteReview {
                DiffyStatusBanner(message: "You have a pending review on GitHub. Open it there to finish or discard it, then refresh here.")
            }
            if let details = self.viewModel.details, !details.hasAllFiles {
                DiffyStatusBanner(message: "GitHub returned \(details.files.count) of \(details.changedFileCount) files. Open GitHub to inspect the remaining files.")
            }
            if let details = self.viewModel.details, !details.hasAllCommits {
                DiffyStatusBanner(message: "GitHub returned \(details.commits.count) of \(details.commitCount) commits. Open GitHub to inspect the remaining commits.")
            }

        }
        .padding(.horizontal, 24)

    }

    private func syncAnnotations() {
        self.aiWorkspace.updateAnnotations(self.matchingNotes)
    }

    @ViewBuilder
    private func content() -> some View {

        if self.viewModel.isLoading && self.viewModel.details == nil && !self.isShowingAIContent {
            DiffyLoadingState(title: "Loading Pull Request & Discussions…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.viewModel.details == nil
                    && !self.isShowingAIContent
                    && (self.aiWorkspace.hasAnyGeneration || !self.aiWorkspace.noteFixes.isEmpty) {
            DiffyEmptyState(
                symbol: "wifi.slash",
                title: "Current Pull Request Unavailable",
                message: "Saved AI analyses remain available in the navigation bar. Refresh to load the current files and discussion."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.viewModel.details != nil || self.aiWorkspace.hasAnyGeneration || !self.aiWorkspace.noteFixes.isEmpty {

            switch self.viewModel.selectedTab {

            case .conversation:
                PullRequestConversationView(viewModel: self.viewModel)

            case .commits:
                PullRequestCommitsView(viewModel: self.viewModel)

            case .filesChanged:
                if let selection = self.viewModel.historicalFileSelection {
                    PullRequestHistoricalFileView(selection: selection, close: self.viewModel.closeHistoricalFile)
                } else {
                    PullRequestFilesView(viewModel: self.viewModel, workspace: self.workspace)
                }

            case .learningPath, .architectureMap, .riskMap:
                if let visualization = self.viewModel.selectedTab.visualization {
                    AIReviewWorkspaceView(
                        viewModel: self.aiWorkspace,
                        visualization: visualization,
                        onOpenFile: self.viewModel.openAnalyzedFile
                    )
                }

            case .aiNotes:
                aiNotesContent()

            }

        } else {
            DiffyEmptyState(symbol: "arrow.triangle.pull", title: "Review On GitHub", message: "Choose a connected account and refresh to load this pull request.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    }

    private func tab(for visualization: AIVisualization) -> PullRequestReviewTab {

        switch visualization {
        case .learningPath: .learningPath
        case .architectureMap: .architectureMap
        case .riskMap: .riskMap
        }

    }

    private func aiNotesContent() -> some View {

        AINoteFixView(
            viewModel: self.aiWorkspace,
            canApply: self.aiWorkspace.proposedFixEntry.map {
                self.patchReview.canApply(entry: $0, current: self.viewModel.details)
            } ?? false,
            isApplying: self.patchReview.isApplying,
            applyError: self.patchReview.errorMessage,
            applyNotice: self.patchReview.notice,
            onApply: { entry in
                Task { await self.patchReview.apply(entry: entry, current: self.viewModel.details) }
            },
            onOpenFile: self.viewModel.openNoteFixFile
        )

    }
}
