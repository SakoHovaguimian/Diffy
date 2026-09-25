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

                        if self.viewModel.isRefreshing {
                            ProgressView("Refreshing assigned pull requests…")
                                .font(.system(size: 11))
                        }

                        pullRequestsSection()
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
        .task(id: self.refreshKey) {
            await self.viewModel.refresh(projects: self.workspace.projects, accounts: self.accounts.accounts)
        }

    }

    private func heading() -> some View {

        HStack(alignment: .bottom, spacing: 16) {

            DiffyPageHeading(
                eyebrow: "Workspace",
                title: self.workspace.projects.isEmpty ? "Connect your work." : "Where things stand.",
                detail: self.workspace.projects.isEmpty
                    ? "Add a local project and connect GitHub to bring your work into one place."
                    : "Local changes across your projects and pull requests assigned to your connected accounts."
            )

            if !self.workspace.projects.isEmpty || !self.accounts.accounts.isEmpty {

                Button {
                    self.refreshGeneration += 1
                } label: {
                    Label("Refresh overview", systemImage: "arrow.clockwise")
                }
                .disabled(self.viewModel.isRefreshing)
                .help("Refresh local changes and assigned pull requests")

            }

        }

    }

    private func sections() -> some View {

        VStack(alignment: .leading, spacing: 18) {

            if self.viewModel.isRefreshing {
                ProgressView("Refreshing overview…")
                    .font(.system(size: 11))
            }

            ViewThatFits(in: .horizontal) {

                HStack(alignment: .top, spacing: 18) {

                    projectsSection().frame(minWidth: 320, maxWidth: .infinity)
                    pullRequestsSection().frame(minWidth: 320, maxWidth: .infinity)

                }

                VStack(spacing: 18) {

                    projectsSection()
                    pullRequestsSection()

                }

            }

        }

    }

    private func projectsSection() -> some View {

        VStack(alignment: .leading, spacing: 0) {

            sectionHeading("Projects with diffs", count: self.viewModel.activeProjects.count, symbol: "square.stack.3d.up")

            if let error = self.viewModel.projectError {
                DiffyStatusBanner(message: error, isError: true).padding([.horizontal, .bottom], 18)
            }

            if self.viewModel.activeProjects.isEmpty, self.viewModel.hasLoaded, self.viewModel.projectError == nil {

                if self.workspace.runtime.isLive && !self.workspace.projects.contains(where: { $0.repositoryReference != nil }) {
                    sectionEmpty(symbol: "folder.badge.plus", title: "No local checkouts", detail: "Add a local Git folder to see its changes here.")
                } else {
                    sectionEmpty(symbol: "checkmark.circle", title: "No active diffs", detail: "Your local projects have no changes to review.")
                }

            } else {

                LazyVStack(spacing: 0) {

                    ForEach(self.viewModel.activeProjects) { change in

                        OverviewProjectRow(
                            change: change,
                            bucket: self.workspace.bucket(for: change.project)
                        ) {
                            self.workspace.openWorkingTree(for: change.project)
                        }

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

    private func pullRequestsSection() -> some View {

        VStack(alignment: .leading, spacing: 0) {

            sectionHeading(
                "Assigned pull requests",
                count: self.viewModel.assignedPullRequests.count,
                symbol: "arrow.triangle.pull",
                hasMore: self.viewModel.hasMoreAssignedPullRequests
            )

            if let error = self.viewModel.pullRequestError {
                DiffyStatusBanner(message: error, isError: true).padding([.horizontal, .bottom], 18)
            }

            if self.viewModel.assignedPullRequests.isEmpty, self.viewModel.hasLoaded, self.viewModel.pullRequestError == nil {

                if !self.workspace.runtime.isLive {
                    sectionEmpty(symbol: "person.crop.circle", title: "GitHub is in Diffy Live", detail: "Open Diffy Live to connect an account and see assigned pull requests.")
                } else if self.accounts.accounts.isEmpty {

                    sectionEmpty(symbol: "person.crop.circle.badge.plus", title: "Connect GitHub", detail: "Connect an account to see pull requests assigned to you.")
                    SettingsLink { Text("Open Accounts") }
                        .buttonStyle(.bordered)
                        .padding([.horizontal, .bottom], 18)

                } else if self.accounts.accounts.allSatisfy({ $0.status != .connected }) {

                    sectionEmpty(symbol: "person.crop.circle.badge.exclamationmark", title: "Reconnect GitHub", detail: "Reconnect an account in Settings to see assigned pull requests.")
                    SettingsLink { Text("Open Accounts") }
                        .buttonStyle(.bordered)
                        .padding([.horizontal, .bottom], 18)

                } else {
                    sectionEmpty(symbol: "tray", title: "Nothing assigned", detail: "No open pull requests are assigned to your connected accounts.")
                }

            } else {

                LazyVStack(spacing: 0) {

                    ForEach(self.viewModel.assignedPullRequests) { item in

                        OverviewPullRequestRow(request: item)

                        if item.id != self.viewModel.assignedPullRequests.last?.id {
                            self.theme.border.frame(height: 1).padding(.leading, 18)
                        }

                    }

                }

                if self.viewModel.hasMoreAssignedPullRequests {

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Showing up to 100 recently updated requests per account. GitHub may have more.")
                            .font(.system(size: 10))
                            .foregroundStyle(self.theme.secondaryText)

                        ForEach(self.accounts.accounts.filter { $0.status == .connected }) { account in

                            if let url = assignedPullRequestsURL(for: account) {
                                Link("View all for \(account.handle) on GitHub", destination: url)
                                    .font(.system(size: 10, weight: .medium))
                            }

                        }

                    }
                    .padding(18)

                }

            }

        }
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

    }

    private func sectionHeading(_ title: String, count: Int, symbol: String, hasMore: Bool = false) -> some View {

        HStack(alignment: .firstTextBaseline, spacing: 10) {

            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(self.theme.accent)

            Text(title)
                .font(.system(size: 15, weight: .semibold))

            Spacer(minLength: 8)

            Text(hasMore ? "\(count.formatted())+" : count.formatted())
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

            title = "GitHub in Diffy Live"
            detail = "Open Diffy Live to link an account and see assigned pull requests."

        } else if self.accounts.accounts.isEmpty {

            title = "Connect GitHub"
            detail = "Link your first account to find repositories and assigned pull requests."

        } else {

            title = "GitHub connected"
            detail = "Browse your repositories in Accounts to link or clone one."

        }

        return welcomeStep(
            symbol: "person.crop.circle.badge.plus",
            title: title,
            detail: detail
        ) {

            if self.workspace.runtime.isLive {
                SettingsLink { Text(self.accounts.accounts.isEmpty ? "Connect GitHub" : "Browse repositories") }
                    .buttonStyle(.bordered)
            }

        }

    }

    private func projectWelcomeStep() -> some View {

        welcomeStep(
            symbol: "folder.badge.plus",
            title: "Add your first project",
            detail: "Choose a local Git folder. Diffy will show its changes here, with or without GitHub."
        ) {

            Button("Choose Project Folder") {

                guard let directory = ProjectDirectoryController().chooseDirectory() else { return }
                self.workspace.prepareProject(directoryURL: directory, in: nil)

            }
            .buttonStyle(.borderedProminent)

        }

    }

    private func assignedPullRequestsURL(for account: GitHubAccount) -> URL? {

        var components = URLComponents()
        components.scheme = "https"
        components.host = account.host
        components.path = "/issues"
        components.queryItems = [URLQueryItem(name: "q", value: "is:pr is:open assignee:\(account.login)")]

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
