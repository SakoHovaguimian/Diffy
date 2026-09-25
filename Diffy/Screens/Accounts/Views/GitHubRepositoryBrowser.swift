import SwiftUI

struct GitHubRepositoryBrowser: View {

    @ObservedObject var viewModel: GitHubAccountsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Repositories").font(.system(size: 18, weight: .semibold))
                Spacer()
                Picker("Account", selection: self.$viewModel.selectedAccountID) {
                    ForEach(self.viewModel.accounts) { Text($0.handle).tag($0.id) }
                }
                .labelsHidden()
                .frame(maxWidth: 190)
                .disabled(self.viewModel.isImporting)
                Button {
                    Task { await self.viewModel.loadRepositories() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh repositories")
                .disabled(self.viewModel.isLoadingRepositories)

            }
            HStack {

                TextField("Filter loaded repositories", text: self.$viewModel.search)
                    .textFieldStyle(.roundedBorder)
                if !self.viewModel.search.isEmpty {
                    Button("Clear") { self.viewModel.search = "" }
                }
                Picker("Clone using", selection: self.$viewModel.cloneTransport) {
                    ForEach(GitCloneTransport.allCases) { Text($0.title).tag($0) }
                }
                .frame(width: 175)

            }
            Text("Link an existing checkout, or choose a parent folder to clone into. Git uses this Mac's SSH agent or credential helper.")
                .font(.system(size: 11))
                .foregroundStyle(self.theme.secondaryText)

            if self.viewModel.isImporting {
                ProgressView("Adding repository…").controlSize(.small)
            }

            LazyVStack(spacing: 0) {

                ForEach(self.viewModel.visibleRepositories) { repository in
                    repositoryRow(repository)
                }

            }
            .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 10))

            if self.viewModel.isLoadingRepositories {
                ProgressView("Loading repositories…").controlSize(.small)
            } else if self.viewModel.visibleRepositories.isEmpty {
                Text(self.viewModel.search.isEmpty ? "No repositories are visible to this account. Check the app installation or token's repository access, then refresh." : "No loaded repositories match this filter.")
                    .font(.system(size: 12))
                    .foregroundStyle(self.theme.secondaryText)
            }

            if self.viewModel.hasMoreRepositories {
                Button("Load more repositories") { Task { await self.viewModel.loadRepositories(loadMore: true) } }
                    .disabled(self.viewModel.isLoadingRepositories)
            }

            if let url = self.viewModel.accountService.configuration.installationURL {
                Link("Manage GitHub App repository access ↗", destination: url)
            }

        }

    }

    private func repositoryRow(_ repository: GitHubRepositorySummary) -> some View {

        HStack(spacing: 12) {

            Image(systemName: repository.isPrivate ? "lock" : "shippingbox")
                .foregroundStyle(self.theme.accent)
            VStack(alignment: .leading, spacing: 5) {

                Text(repository.fullName).font(.system(size: 12, weight: .semibold)).lineLimit(1).truncationMode(.middle)
                Text(repository.summary ?? repository.defaultBranch)
                    .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText).lineLimit(2)

            }
            Spacer(minLength: 12)
            repositoryActions(for: repository)

        }
        .padding(14)
        .disabled(self.viewModel.isImporting)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func repositoryActions(for repository: GitHubRepositorySummary) -> some View {

        HStack(spacing: 8) {

            Button("Link") { chooseFolder(repository, clone: false) }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .accessibilityLabel("Link folder")
                .help("Link an existing local folder")
            Button("Clone") { chooseFolder(repository, clone: true) }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                .help("Clone into a local folder")

        }
        .frame(width: 140, alignment: .trailing)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)

    }

    private func chooseFolder(_ repository: GitHubRepositorySummary, clone: Bool) {

        guard let folder = ProjectDirectoryController().chooseDirectory() else { return }
        self.viewModel.link(repository, folder: folder, clone: clone)

    }

}
