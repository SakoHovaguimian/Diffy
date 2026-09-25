import SwiftUI

struct RepositoryActionBar: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 12) {

            Label(self.viewModel.snapshot?.head.displayName ?? "Repository", systemImage: "arrow.triangle.branch")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 12)

            if self.viewModel.isOperating {

                ProgressView().controlSize(.small)
                Text(self.viewModel.operationTitle).font(.system(size: 11))
                Button("Stop") { self.viewModel.cancelOperation() }

            } else {
                operationButtons()
            }

            Button {
                Task { await self.viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh Repository")
            .accessibilityLabel("Refresh Repository")
            .disabled(self.viewModel.isRefreshing || self.viewModel.isOperating)

        }
        .controlSize(.small)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }
        .sheet(isPresented: self.$viewModel.showsAddRemote) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Git Remote").font(.headline)
                Text("Add a remote, fetch its branches, then choose one as this branch’s upstream.")
                    .font(.system(size: 12))
                    .foregroundStyle(self.theme.secondaryText)
                TextField("Remote Name", text: self.$viewModel.newRemoteName)
                TextField("HTTPS Or SSH URL", text: self.$viewModel.newRemoteURL)
                HStack {
                    Spacer()
                    Button("Cancel") { self.viewModel.showsAddRemote = false }
                    Button("Add Remote") {
                        self.viewModel.request(.addRemote(name: self.viewModel.newRemoteName, url: self.viewModel.newRemoteURL))
                        self.viewModel.showsAddRemote = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(self.viewModel.newRemoteName.isEmpty || self.viewModel.newRemoteURL.isEmpty)
                }
            }
            .padding(24)
            .frame(width: 440)
            .diffyStyle()
        }

    }

    private func operationButtons() -> some View {

        HStack(spacing: 8) {

            Button { self.viewModel.request(.fetch(remote: nil)) } label: { Label("Fetch", systemImage: "arrow.down.circle") }
                .disabled(!self.viewModel.canMutate || (self.viewModel.snapshot?.remotes.isEmpty ?? true))
            Menu {

                if self.viewModel.snapshot?.upstream != nil {
                    ForEach(GitPullStrategy.allCases) { strategy in
                        Button(strategy.title) { self.viewModel.request(.pull(strategy)) }
                    }
                } else {
                    Text("Choose A Tracking Branch")
                    ForEach(self.viewModel.snapshot?.remoteBranches ?? []) { branch in
                        Button(branch.name) { self.viewModel.request(.setUpstream(branch: branch.name)) }
                    }
                    if self.viewModel.snapshot?.remoteBranches.isEmpty ?? true {
                        if self.viewModel.snapshot?.remotes.isEmpty ?? true {
                            Button("Add A Remote…") { self.viewModel.showsAddRemote = true }
                        } else {
                            Button("Fetch Remote Branches") { self.viewModel.request(.fetch(remote: nil)) }
                            Text("You can also publish this branch with Push.")
                        }
                    }
                }

            } label: {
                Label("Pull", systemImage: "arrow.down")
            }
            .disabled(!self.viewModel.canMutate)
            Menu {

                Button("Push") { self.viewModel.request(.push(GitPushOptions())) }
                    .disabled(self.viewModel.snapshot?.upstream == nil)
                Menu("Publish Branch To") {

                    ForEach(self.viewModel.snapshot?.remotes ?? []) { remote in
                        Button(remote.name) { self.viewModel.request(.push(GitPushOptions(remote: remote.name, setsUpstream: true))) }
                    }

                }
                Divider()
                Button("Force Push With Lease…") { self.viewModel.request(.push(GitPushOptions(forceWithLease: true))) }
                    .disabled(self.viewModel.snapshot?.upstream == nil)

            } label: {
                Label("Push", systemImage: "arrow.up")
            }
            .disabled(!self.viewModel.canMutate || (self.viewModel.snapshot?.remotes.isEmpty ?? true))

        }
        .help(self.viewModel.runtime.isLive ? "Git uses this Mac's existing remote credentials." : "Git actions are available in Diffy Live.")

    }

}
