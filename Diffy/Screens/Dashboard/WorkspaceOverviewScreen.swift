import SwiftUI

struct WorkspaceOverviewScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var viewModel: WorkspaceOverviewViewModel
    @EnvironmentObject private var accounts: GitHubAccountsViewModel
    @Environment(\.diffyTheme) private var theme
    @State private var refreshGeneration = 0

    private var refreshKey: RefreshKey {
        RefreshKey(projects: self.workspace.projects, accounts: self.accounts.accounts, generation: self.refreshGeneration)
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                heading()

                if self.workspace.projects.isEmpty {
                    welcome()

                    if !self.accounts.accounts.isEmpty {

                        if self.viewModel.isLoadingPullRequests {
                            ProgressView("Refreshing Pull Requests…")
                                .font(.system(size: 11))
                        }

                        pullRequestsSection()
                        pullRequestsSection(reviewRequested: true)
                    }
                } else {
                    sections()
                }

            }
            .padding(32)
            .frame(maxWidth: 1160, alignment: .leading)
            .frame(maxWidth: .infinity)

        }
        .background(self.theme.background)
        .sheet(item: self.$viewModel.gitHubReview, onDismiss: { self.refreshGeneration += 1 }) { review in
            PullRequestReviewScreen(viewModel: review).diffyStyle()
        }
        .task(id: self.refreshKey) {
            await self.viewModel.refresh(projects: self.workspace.projects, accounts: self.accounts.accounts)
        }

    }

    private func heading() -> some View {

        HStack(alignment: .bottom, spacing: 16) {

            DiffyPageHeading(
                eyebrow: "Workspace",
                title: self.workspace.projects.isEmpty ? "Connect Your Work." : "Where Things Stand.",
                detail: self.workspace.projects.isEmpty
                    ? "Add a local project and connect GitHub to bring your work into one place."
                    : "Local changes, tracked branches, and pull requests for your connected accounts."
            )

            if !self.workspace.projects.isEmpty || !self.accounts.accounts.isEmpty {

                Button {
                    self.refreshGeneration += 1
                } label: {
                    Label("Refresh Overview", systemImage: "arrow.clockwise")
                }
                .disabled(self.viewModel.isRefreshing)
                .help("Refresh Local Changes & Pull Requests")

            }

        }

    }

    private func sections() -> some View {

        VStack(alignment: .leading, spacing: 18) {

            if self.viewModel.isLoadingProjects || self.viewModel.isLoadingPullRequests {
                ProgressView("Refreshing \(self.viewModel.isLoadingProjects ? "Projects" : "Pull Requests")…")
                    .font(.system(size: 11))
            }

            ViewThatFits(in: .horizontal) {

                HStack(alignment: .top, spacing: 32) {

                    projectsSection().frame(minWidth: 340, maxWidth: .infinity)
                    VStack(spacing: 24) {
                        pullRequestsSection()
                        pullRequestsSection(reviewRequested: true)
                    }
                    .frame(minWidth: 340, maxWidth: .infinity)

                }

                VStack(spacing: 24) {

                    projectsSection()
                    pullRequestsSection()
                    pullRequestsSection(reviewRequested: true)

                }

            }

        }

    }

    private func projectsSection() -> some View {

        VStack(alignment: .leading, spacing: 0) {

            sectionHeading("Projects Needing Attention", count: self.viewModel.activeProjects.count, symbol: "square.stack.3d.up", isLoading: self.viewModel.isLoadingProjects)

            if self.viewModel.activeProjects.isEmpty, self.viewModel.isLoadingProjects {
                ProgressView("Reading Local Projects…").padding(18)
            }

            if let error = self.viewModel.projectError {
                DiffyStatusBanner(message: error, isError: true).padding([.horizontal, .bottom], 18)
            }

            if self.viewModel.activeProjects.isEmpty, self.viewModel.hasLoadedProjects, self.viewModel.projectError == nil {

                if self.workspace.runtime.isLive && !self.workspace.projects.contains(where: { $0.repositoryReference != nil }) {
                    sectionEmpty(symbol: "folder.badge.plus", title: "No Local Checkouts", detail: "Add a local Git folder to see its changes here.")
                } else {
                    sectionEmpty(symbol: "checkmark.circle", title: "Nothing Pending", detail: "No local changes or branches behind their last fetched upstream.")
                }

            } else {

                LazyVStack(spacing: 0) {

                    ForEach(self.viewModel.activeProjects) { change in

                        OverviewProjectRow(
                            change: change,
                            bucket: self.workspace.bucket(for: change.project),
                            open: { self.workspace.openWorkingTree(for: change.project) },
                            pull: { self.workspace.pullFromOverview(for: change.project) }
                        )

                        if change.id != self.viewModel.activeProjects.last?.id {
                            self.theme.border.frame(height: 1).padding(.leading, 18)
                        }

                    }

                }

            }

        }
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

    }

    private func pullRequestsSection(reviewRequested: Bool = false) -> some View {

        let requests = reviewRequested ? self.viewModel.sortedReviewRequestedPullRequests : self.viewModel.sortedAssignedPullRequests
        let sortOrder = reviewRequested ? self.viewModel.reviewRequestedSortOrder : self.viewModel.assignedSortOrder
        let sortSelection = reviewRequested ? self.$viewModel.reviewRequestedSortOrder : self.$viewModel.assignedSortOrder
        let collapsedGroups = reviewRequested ? self.$viewModel.collapsedReviewRequestedGroups : self.$viewModel.collapsedAssignedGroups
        let hasMore = reviewRequested ? self.viewModel.hasMoreReviewRequestedPullRequests : self.viewModel.hasMoreAssignedPullRequests
        let isLoading = reviewRequested ? self.viewModel.isLoadingReviewRequested : self.viewModel.isLoadingAssigned
        let hasLoaded = reviewRequested ? self.viewModel.hasLoadedReviewRequested : self.viewModel.hasLoadedAssigned
        let error = reviewRequested ? self.viewModel.reviewRequestedError : self.viewModel.assignedError

        return VStack(alignment: .leading, spacing: 0) {

            sectionHeading(
                reviewRequested ? "Reviews Requested By Me" : "Assigned Pull Requests",
                count: requests.count,
                symbol: "arrow.triangle.pull",
                hasMore: hasMore,
                isLoading: isLoading,
                sortSelection: sortSelection
            )

            if requests.isEmpty, isLoading {
                ProgressView("Loading Pull Requests…").padding(18)
            }

            if let error {
                DiffyStatusBanner(message: error, isError: true).padding([.horizontal, .bottom], 18)
            }

            if requests.isEmpty, hasLoaded, error == nil {

                if !self.workspace.runtime.isLive {
                    sectionEmpty(symbol: "person.crop.circle", title: "GitHub Is In Diffy Live", detail: "Open Diffy Live to connect an account and see assigned pull requests.")
                } else if self.accounts.accounts.isEmpty {

                    sectionEmpty(symbol: "person.crop.circle.badge.plus", title: "Connect GitHub", detail: "Connect an account to see your pull requests.")
                    SettingsLink { Text("Open Accounts") }
                        .buttonStyle(.bordered)
                        .padding([.horizontal, .bottom], 18)

                } else if self.accounts.accounts.allSatisfy({ $0.status != .connected }) {

                    sectionEmpty(symbol: "person.crop.circle.badge.exclamationmark", title: "Reconnect GitHub", detail: "Reconnect an account in Settings to see your pull requests.")
                    SettingsLink { Text("Open Accounts") }
                        .buttonStyle(.bordered)
                        .padding([.horizontal, .bottom], 18)

                } else {
                    sectionEmpty(symbol: "tray", title: reviewRequested ? "No Review Requests" : "Nothing Assigned", detail: reviewRequested ? "No open pull requests request your review directly." : "No open pull requests are assigned to your connected accounts.")
                }

            } else {

                OverviewPullRequestList(requests: requests, sortOrder: sortOrder, hasFooter: hasMore, collapsedGroups: collapsedGroups) { request in
                    self.viewModel.reviewPullRequest(request, accounts: self.accounts.accounts)
                }

                if hasMore {

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Showing up to 100 recently updated requests per account. GitHub may have more.")
                            .font(.system(size: 10))
                            .foregroundStyle(self.theme.secondaryText)

                        ForEach(self.accounts.accounts.filter { $0.status == .connected }) { account in

                            if let url = pullRequestsURL(for: account, reviewRequested: reviewRequested) {
                                Link("View All For \(account.handle) On GitHub", destination: url)
                                    .font(.system(size: 10, weight: .medium))
                            }

                        }

                    }
                    .padding(18)

                }

            }

        }
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border))

    }

    private func sectionHeading(
        _ title: String,
        count: Int,
        symbol: String,
        hasMore: Bool = false,
        isLoading: Bool = false,
        sortSelection: Binding<OverviewPullRequestSortOrder>? = nil
    ) -> some View {

        HStack(alignment: .firstTextBaseline, spacing: 10) {

            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(self.theme.accent)

            Text(title)
                .font(.system(size: 15, weight: .semibold))

            Spacer(minLength: 8)

            if let sortSelection {

                Menu {

                    Picker("Sort By", selection: sortSelection) {
                        ForEach(OverviewPullRequestSortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }

                    if hasMore {
                        Divider()
                        Text("Sorting applies to the requests shown here.")
                    }

                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .controlSize(.small)
                .accessibilityLabel("Sort \(title)")
                .help("Sort By \(sortSelection.wrappedValue.rawValue)")

            }

            if isLoading {
                ProgressView().controlSize(.small)
            }

            Text(hasMore || isLoading ? "\(count.formatted())+" : count.formatted())
                .font(.system(size: 26, weight: .light, design: .rounded))
                .foregroundStyle(self.theme.secondaryText)

        }
        .padding(18)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func sectionEmpty(symbol: String, title: String, detail: String) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Image(systemName: symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(self.theme.secondaryText)

            Text(title)
                .font(.system(size: 13, weight: .semibold))

            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(self.theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(18)

    }

    private func welcome() -> some View {

        ViewThatFits(in: .horizontal) {

            HStack(alignment: .top, spacing: 18) {
                githubWelcomeStep().frame(minWidth: 300)
                projectWelcomeStep().frame(minWidth: 300)
            }

            VStack(spacing: 18) {
                githubWelcomeStep()
                projectWelcomeStep()
            }

        }

    }

    private func githubWelcomeStep() -> some View {

        let title: String
        let detail: String

        if !self.workspace.runtime.isLive {

            title = "GitHub In Diffy Live"
            detail = "Open Diffy Live to link an account and see assigned pull requests."

        } else if self.accounts.accounts.isEmpty {

            title = "Connect GitHub"
            detail = "Link your first account to find repositories and assigned pull requests."

        } else {

            title = "GitHub Connected"
            detail = "Browse your repositories in Accounts to link or clone one."

        }

        return welcomeStep(
            symbol: "person.crop.circle.badge.plus",
            title: title,
            detail: detail
        ) {

            if self.workspace.runtime.isLive {
                SettingsLink { Text(self.accounts.accounts.isEmpty ? "Connect GitHub" : "Browse Repositories") }
                    .buttonStyle(.bordered)
            }

        }

    }

    private func projectWelcomeStep() -> some View {

        welcomeStep(
            symbol: "folder.badge.plus",
            title: "Add Your First Project",
            detail: "Choose a local Git folder. Diffy will show its changes here, with or without GitHub."
        ) {

            Button("Choose Project Folder") {

                guard let directory = ProjectDirectoryController().chooseDirectory() else { return }
                self.workspace.prepareProject(directoryURL: directory, in: nil)

            }
            .buttonStyle(.borderedProminent)

        }

    }

    private func pullRequestsURL(for account: GitHubAccount, reviewRequested: Bool) -> URL? {

        var components = URLComponents()
        components.scheme = "https"
        components.host = account.host
        components.path = "/issues"
        let qualifier = reviewRequested ? "review-requested:" : "assignee:"
        components.queryItems = [URLQueryItem(name: "q", value: "is:pr is:open \(qualifier)\(account.login)")]

        return components.url

    }

    private func welcomeStep<Content: View>(
        symbol: String,
        title: String,
        detail: String,
        @ViewBuilder action: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            Image(systemName: symbol)
                .font(.system(size: 23, weight: .light))
                .foregroundStyle(self.theme.accent)
                .frame(width: 46, height: 46)
                .background(self.theme.selection, in: RoundedRectangle(cornerRadius: 10))

            Text(title)
                .font(.system(size: 17, weight: .semibold))

            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 10)
            action()

        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 240, alignment: .leading)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

    }

}

private struct RefreshKey: Equatable {
    let projects: [RepositoryProject]
    let accounts: [GitHubAccount]
    let generation: Int
}

#Preview {

    let workspace = mockResolve(WorkspaceViewModel.self)
    WorkspaceOverviewScreen(workspace: workspace, viewModel: workspace.overviewViewModel)
        .frame(width: 1080, height: 720)
        .withMockPreviews()

}
