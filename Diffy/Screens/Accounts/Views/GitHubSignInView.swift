import SwiftUI

struct GitHubSignInView: View {

    @ObservedObject var viewModel: GitHubAccountsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            if let authorization = self.viewModel.authorization {
                deviceAuthorization(authorization)
            } else {

                HStack {

                    Button {
                        self.viewModel.signIn()
                    } label: {
                        Label("Sign in with GitHub", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.viewModel.runtime.isLive || self.viewModel.isSigningIn)

                    if self.viewModel.isSigningIn {

                        ProgressView().controlSize(.small)
                        Button("Cancel") { self.viewModel.cancelSignIn() }

                    }

                }

                if !self.viewModel.runtime.isLive {
                    Text("Accounts are isolated in Mock mode. Open Diffy Live to connect GitHub.")
                } else if !self.viewModel.accountService.configuration.isConfigured {
                    Text("Browser sign-in uses the GitHub CLI installed on this Mac. GitHub will ask you to authorize GitHub CLI, then Diffy will connect the approved account.")
                    if let url = URL(string: "https://cli.github.com/") {
                        Link("Get GitHub CLI ↗", destination: url)
                    }
                }

                if self.viewModel.runtime.isLive {
                    tokenEntry()
                }

            }

        }
        .font(.system(size: 12))
        .foregroundStyle(self.theme.secondaryText)

    }

    private func deviceAuthorization(_ authorization: GitHubSignInChallenge) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Sign in through \(authorization.providerName)").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            Text("Enter this code on GitHub").font(.system(size: 14, weight: .semibold)).foregroundStyle(self.theme.text)
            HStack(spacing: 16) {

                Text(authorization.userCode)
                    .font(.system(size: 26, weight: .medium, design: .monospaced))
                    .tracking(2)
                    .textSelection(.enabled)
                    .foregroundStyle(self.theme.text)
                Button("Copy code") { ExternalLinkController().copy(authorization.userCode) }
                Spacer()

            }
            HStack {

                Button("Open GitHub") { ExternalLinkController().open(authorization.verificationURL) }
                    .buttonStyle(.borderedProminent)
                Button("Cancel") { self.viewModel.cancelSignIn() }
                Spacer()
                ProgressView().controlSize(.small)
                Text("Waiting for approval…")

            }
            Text("Code expires at \(authorization.expiresAt.formatted(date: .omitted, time: .shortened)).")

        }
        .padding(20)
        .background(self.theme.selection, in: RoundedRectangle(cornerRadius: 12))

    }

    private func tokenEntry() -> some View {

        DisclosureGroup("Connect with a personal access token") {

            VStack(alignment: .leading, spacing: 12) {

                Text("Use a fine-grained token with access to the repositories you want to view. Enable Contents and Pull requests read permissions. Credentials are stored in the macOS Keychain.")
                    .fixedSize(horizontal: false, vertical: true)
                HStack {

                    Group {

                        if self.viewModel.showsToken {
                            TextField("Personal access token", text: self.$viewModel.personalAccessToken)
                        } else {
                            SecureField("Personal access token", text: self.$viewModel.personalAccessToken)
                        }

                    }
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { self.viewModel.connectToken() }
                    Button {
                        self.viewModel.showsToken.toggle()
                    } label: {
                        Image(systemName: self.viewModel.showsToken ? "eye.slash" : "eye")
                    }
                    .accessibilityLabel(self.viewModel.showsToken ? "Hide token" : "Show token")
                    Button("Connect") { self.viewModel.connectToken() }
                        .disabled(self.viewModel.personalAccessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.viewModel.isSigningIn)

                }
                if let url = URL(string: "https://\(self.viewModel.accountService.configuration.host)/settings/personal-access-tokens/new") {
                    Link("Create a token on GitHub ↗", destination: url)
                }

            }
            .padding(.top, 12)

        }

    }

}
