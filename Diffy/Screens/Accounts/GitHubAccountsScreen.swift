import SwiftUI

struct GitHubAccountsScreen: View {

    @EnvironmentObject private var viewModel: GitHubAccountsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                DiffyPageHeading(eyebrow: "Connections", title: "Your Work, Connected.", detail: "Connect GitHub, then link a checkout or clone a repository into your workspace.")
                accountList()
                GitHubSignInView(viewModel: self.viewModel)

                if let error = self.viewModel.errorMessage {
                    DiffyStatusBanner(message: error, isError: true)
                }

                if let notice = self.viewModel.notice {
                    DiffyStatusBanner(message: notice)
                }

                if !self.viewModel.accounts.isEmpty {
                    GitHubRepositoryBrowser(viewModel: self.viewModel)
                }

            }
            .padding(24)

        }
        .background(self.theme.background)
        .task(id: self.viewModel.selectedAccountID) {
            await self.viewModel.loadRepositories()
        }
        .confirmationDialog("Disconnect GitHub Account?", isPresented: Binding(
            get: { self.viewModel.accountToRemove != nil },
            set: { if !$0 { self.viewModel.accountToRemove = nil } }
        ), titleVisibility: .visible) {

            Button("Disconnect", role: .destructive) {

                if let account = self.viewModel.accountToRemove {
                    Task { await self.viewModel.removeAccount(account) }
                }

            }

            Button("Cancel", role: .cancel) { self.viewModel.accountToRemove = nil }

        } message: {
            Text("Remove \(self.viewModel.accountToRemove?.handle ?? "this account") and its credential from this Mac. Local folders and projects stay in Diffy. You can revoke the app or token separately on GitHub.")
        }

    }

    private func accountList() -> some View {

        VStack(spacing: 0) {

            ForEach(self.viewModel.accounts) { account in

                HStack(spacing: 14) {

                    Text(account.initials)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(self.theme.accent)
                        .frame(width: 42, height: 42)
                        .background(self.theme.selection, in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {

                        Text(account.displayName ?? account.login).font(.system(size: 13, weight: .semibold))
                        Text("\(account.handle) · \(account.host)").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)

                    }
                    Spacer()
                    DiffyBadge(title: account.status.title, color: account.status == .connected ? self.theme.added : self.theme.modified)

                    Menu {

                        Button("Reconnect") { self.viewModel.signIn(reconnecting: account) }

                        Button("Disconnect…", role: .destructive) { self.viewModel.accountToRemove = account }

                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                    .disabled(self.viewModel.isSigningIn || self.viewModel.isImporting)
                    .accessibilityLabel("Manage \(account.handle)")

                }
                .padding(16)

            }

        }
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))

    }

}

#Preview {

    GitHubAccountsScreen()
        .frame(width: 760, height: 680)
        .withMockPreviews()

}
