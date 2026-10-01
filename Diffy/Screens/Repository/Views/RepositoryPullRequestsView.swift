import SwiftUI

struct RepositoryPullRequestsView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @EnvironmentObject private var accounts: GitHubAccountsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                DiffyPageHeading(eyebrow: "GitHub", title: "Ready For Another Pair Of Eyes.", detail: self.viewModel.linkedRepository?.fullName ?? "Link a GitHub repository to see its pull requests.")

                if self.viewModel.availableAccounts.isEmpty || self.viewModel.linkedRepository == nil {

                    VStack(spacing: 0) {

                        DiffyEmptyState(symbol: "person.crop.circle.badge.plus", title: "Connect Your Repository", message: "Sign in through Settings → Accounts, then link this checkout. Existing GitHub remotes are detected automatically.")
                        SettingsLink { Text("Open Settings") }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom, 28)

                    }
                    .frame(maxWidth: .infinity)

                } else {
                    requests()
                }

            }
            .padding(32)

        }
        .onChange(of: self.accounts.accounts) { _, _ in

            self.viewModel.selectedAccountID = self.viewModel.availableAccounts.first?.id ?? ""
            Task { await self.viewModel.loadPullRequests() }

        }
        .diffyStatusAnimation(value: self.viewModel.pullRequestError)

    }

    private func requests() -> some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                Picker("People", selection: self.$viewModel.pullRequestFilter) {
                    ForEach(PullRequestFilter.allCases) { Text($0.title).tag($0) }
                }
                .frame(maxWidth: 200)
                Picker("Status", selection: self.$viewModel.pullRequestStatusFilter) {
                    ForEach(PullRequestStatusFilter.allCases) { Text($0.title).tag($0) }
                }
                .frame(maxWidth: 215)
                Picker("Checks", selection: self.$viewModel.pullRequestCheckFilter) {
                    ForEach(PullRequestCheckFilter.allCases) { Text($0.title).tag($0) }
                }
                .frame(maxWidth: 180)
                Spacer()
                Picker("Account", selection: self.$viewModel.selectedAccountID) {
                    ForEach(self.viewModel.availableAccounts) { Text($0.handle).tag($0.id) }
                }
                .frame(maxWidth: 220)
                Button("Refresh") { Task { await self.viewModel.loadPullRequests() } }
                    .disabled(self.viewModel.isLoadingPullRequests || self.viewModel.isLoadingMorePullRequests)

            }
            .onChange(of: self.viewModel.selectedAccountID) { _, _ in Task { await self.viewModel.loadPullRequests() } }

            if let error = self.viewModel.pullRequestError {
                DiffyStatusBanner(message: error, isError: true)
            }

            if self.viewModel.isLoadingPullRequests {
                DiffyLoadingState(title: "Loading Pull Requests…")
            } else if self.viewModel.visiblePullRequests.isEmpty
                && !self.viewModel.isLoadingMorePullRequests
                && self.viewModel.pullRequestError == nil {
                DiffyEmptyState(symbol: "tray", title: "Nothing Waiting Here", message: "No unmerged pull requests match these filters. Refresh to check again.")
            }

            if self.viewModel.isLoadingMorePullRequests {
                DiffyLoadingState(title: "Loading More Pull Requests…")
            }

            if self.viewModel.isLoadingPullRequestMetadata {
                DiffyLoadingState(title: "Loading Pull Request Details…")
            }

            LazyVStack(spacing: 0) {

                ForEach(self.viewModel.visiblePullRequests) { request in

                    DiffyPullRequestRow(
                        content: PullRequestRowContent(
                            request: request,
                            repositoryFullName: self.viewModel.linkedRepository?.fullName
                        )
                    ) {

                        if let review = self.viewModel.reviewPullRequest(request) {
                            self.workspace.openPullRequest(review)
                        }

                    }
                    .contextMenu {
                        Button("Fetch & Compare Locally") { self.viewModel.inspectPullRequest(request) }
                            .disabled(!self.viewModel.canMutate || self.viewModel.linkedRepository?.remoteName == nil)
                    }
                    .background(self.theme.surface)
                    .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

                }

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

        }

    }

}
