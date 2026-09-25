import SwiftUI

struct PullRequestReviewScreen: View {

    @StateObject var viewModel: PullRequestReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(spacing: 0) {

            header()
            controls()
            messages()

            if self.viewModel.isLoading {
                ProgressView("Loading pull request and discussions…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if self.viewModel.details != nil {

                if self.viewModel.showsConversation {
                    PullRequestConversationView(viewModel: self.viewModel)
                } else {
                    PullRequestFilesView(viewModel: self.viewModel)
                }

            } else {
                DiffyEmptyState(symbol: "arrow.triangle.pull", title: "Review on GitHub", message: "Choose a connected account and refresh to load this pull request.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        }
        .frame(minWidth: 720, idealWidth: 1440, maxWidth: .infinity, minHeight: 480, idealHeight: 900, maxHeight: .infinity)
        .background(self.theme.background)
        .background(ComparisonModalSizingView())
        .interactiveDismissDisabled(self.viewModel.hasDrafts || self.viewModel.isSubmitting)
        .task { await self.viewModel.load() }
        .sheet(isPresented: self.$viewModel.showsReviewComposer) {
            PullRequestSubmitReviewView(viewModel: self.viewModel).diffyStyle()
        }
        .sheet(item: self.$viewModel.commentEditor) { draft in
            PullRequestCommentEditor(draft: draft, save: self.viewModel.saveComment).diffyStyle()
        }
        .confirmationDialog("Discard unpublished comments and close?", isPresented: self.$viewModel.showsDiscardConfirmation, titleVisibility: .visible) {

            Button("Discard and close", role: .destructive) { self.dismiss() }
            Button("Keep reviewing", role: .cancel) {}

        } message: {
            Text("Draft comments are kept in this review page until you submit them. Closing will discard them.")
        }
        .confirmationDialog("Discard drafts and refresh?", isPresented: self.$viewModel.showsReloadConfirmation, titleVisibility: .visible) {

            Button("Discard drafts and refresh", role: .destructive) {

                self.viewModel.discardDrafts()
                Task { await self.viewModel.load() }

            }
            Button("Keep drafts", role: .cancel) {}

        } message: {
            Text("Refreshing loads the current revision. Draft line comments cannot be moved safely to changed code.")
        }

    }

    private func header() -> some View {

        HStack(alignment: .top, spacing: 20) {

            VStack(alignment: .leading, spacing: 7) {

                Text("\(self.viewModel.request.link.fullName) · #\(self.viewModel.request.number)")
                    .font(.system(size: 12)).foregroundStyle(self.theme.secondaryText)
                Text(self.viewModel.details?.summary.title ?? self.viewModel.request.title)
                    .font(.system(size: 22, weight: .semibold)).lineLimit(2).textSelection(.enabled)
                if let summary = self.viewModel.details?.summary {

                    HStack(spacing: 10) {

                        DiffyBadge(title: summary.statusTitle, color: self.theme.accent)
                        Text("\(summary.author.login) · \(summary.headRef) → \(summary.baseRef)")
                            .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText).lineLimit(1)

                    }

                }

            }
            Spacer(minLength: 8)
            Link(destination: self.viewModel.request.webURL) { Label("Open in GitHub", systemImage: "arrow.up.right") }
            Button("Close") {

                if self.viewModel.hasDrafts { self.viewModel.showsDiscardConfirmation = true }
                else { self.dismiss() }

            }
            .keyboardShortcut(.cancelAction)
            .disabled(self.viewModel.isSubmitting)

        }
        .padding(24)
        .background(self.theme.surface)

    }

    private func controls() -> some View {

        HStack(spacing: 16) {

            Picker("Review tab", selection: self.$viewModel.showsConversation) {

                Text("Files changed (\(self.viewModel.details?.changedFileCount ?? 0))").tag(false)
                Text("Conversation").tag(true)

            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 340)
            Spacer(minLength: 0)
            Picker("Review as", selection: self.$viewModel.selectedAccountID) {
                ForEach(self.viewModel.accounts) { Text($0.handle).tag($0.id) }
            }
            .frame(maxWidth: 230)
            .disabled(self.viewModel.isBusy || self.viewModel.hasDrafts)
            .onChange(of: self.viewModel.selectedAccountID) { _, _ in
                Task { await self.viewModel.changeAccount() }
            }
            Button {

                if self.viewModel.hasDrafts { self.viewModel.showsReloadConfirmation = true }
                else { Task { await self.viewModel.load() } }

            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh pull request")
            .disabled(self.viewModel.isBusy)
            Button("Review changes\(self.viewModel.drafts.isEmpty ? "" : " (\(self.viewModel.drafts.count))")") {
                self.viewModel.showsReviewComposer = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(!self.viewModel.canReview)

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func messages() -> some View {

        VStack(spacing: 8) {

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

        }
        .padding(.horizontal, 24)

    }

}
