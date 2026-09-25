import SwiftUI

struct RepositoryPullRequestsView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @EnvironmentObject private var accounts: GitHubAccountsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                DiffyPageHeading(eyebrow: "GitHub", title: "Ready for another pair of eyes.", detail: self.viewModel.linkedRepository?.fullName ?? "Link a GitHub repository to see its pull requests.")

                if self.viewModel.availableAccounts.isEmpty || self.viewModel.linkedRepository == nil {

                    DiffyEmptyState(symbol: "person.crop.circle.badge.plus", title: "Connect your repository", message: "Sign in through Settings → Accounts, then link this checkout. Existing GitHub remotes are detected automatically.")
                    SettingsLink { Text("Open settings") }.buttonStyle(.borderedProminent)

                } else {
                    requests()
                }

            }
            .padding(32)

        }
        .sheet(item: self.$viewModel.gitHubReview, onDismiss: {
            Task { await self.viewModel.loadPullRequests() }
        }) { review in
            PullRequestReviewScreen(viewModel: review).diffyStyle()
        }
        .onChange(of: self.accounts.accounts) { _, _ in

            self.viewModel.selectedAccountID = self.viewModel.availableAccounts.first?.id ?? ""
            Task { await self.viewModel.loadPullRequests() }

        }

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
                    .disabled(self.viewModel.isLoadingPullRequests)

            }
            .onChange(of: self.viewModel.selectedAccountID) { _, _ in Task { await self.viewModel.loadPullRequests() } }

            if let error = self.viewModel.pullRequestError {
                DiffyStatusBanner(message: error, isError: true)
            }

            if self.viewModel.isLoadingPullRequests {
                ProgressView("Loading pull requests…")
            } else if self.viewModel.visiblePullRequests.isEmpty {
                DiffyEmptyState(symbol: "tray", title: "Nothing waiting here", message: "No unmerged pull requests match these filters. Refresh to check again.")
            }

            if self.viewModel.isLoadingChecks {
                ProgressView("Loading check status…")
                    .font(.system(size: 11))
            }

            LazyVStack(spacing: 0) {

                ForEach(self.viewModel.visiblePullRequests) { request in

                    HStack(alignment: .top, spacing: 16) {

                        Image(systemName: "arrow.triangle.pull")
                            .font(.system(size: 18))
                            .foregroundStyle(request.isDraft ? self.theme.secondaryText : self.theme.added)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 9) {

                            Text(request.title).font(.system(size: 14, weight: .semibold))
                            Text("#\(request.number) · \(request.author.login) · \(request.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
                            Label("\(request.headRef) → \(request.baseRef)", systemImage: "arrow.triangle.branch")
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(self.theme.secondaryText)
                            if !request.requestedTeams.isEmpty {
                                Text("Team review: \(request.requestedTeams.map(\.name).joined(separator: ", "))").font(.system(size: 10))
                            }

                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            DiffyBadge(title: request.statusTitle, color: request.isDraft || request.lifecycle == .closedUnmerged ? self.theme.secondaryText : self.theme.added)
                            Label(request.checks?.state.title ?? "Checks not loaded", systemImage: request.checks?.state.symbol ?? "questionmark.circle")
                                .font(.system(size: 10))
                                .foregroundStyle(request.checks?.state == .failure ? self.theme.removed : self.theme.secondaryText)
                        }
                        PullRequestActions(webURL: request.webURL) {
                            self.viewModel.reviewPullRequest(request)
                        }

                    }
                    .contextMenu {
                        Button("Fetch & compare locally") { self.viewModel.inspectPullRequest(request) }
                            .disabled(!self.viewModel.canMutate || self.viewModel.linkedRepository?.remoteName == nil)
                    }
                    .padding(20)
                    .background(self.theme.surface)
                    .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

                }

            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

        }

    }

}
