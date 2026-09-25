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
            .help("Refresh repository")
            .accessibilityLabel("Refresh repository")
            .disabled(self.viewModel.isRefreshing || self.viewModel.isOperating)

        }
        .controlSize(.small)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func operationButtons() -> some View {

        HStack(spacing: 8) {

            Button { self.viewModel.request(.fetch(remote: nil)) } label: { Label("Fetch", systemImage: "arrow.down.circle") }
            Menu {

                ForEach(GitPullStrategy.allCases) { strategy in
                    Button(strategy.title) { self.viewModel.request(.pull(strategy)) }
                }

            } label: {
                Label("Pull", systemImage: "arrow.down")
            }
            .disabled(self.viewModel.snapshot?.upstream == nil)
            Menu {

                Button("Push") { self.viewModel.request(.push(GitPushOptions())) }
                    .disabled(self.viewModel.snapshot?.upstream == nil)
                Menu("Publish branch to") {

                    ForEach(self.viewModel.snapshot?.remotes ?? []) { remote in
                        Button(remote.name) { self.viewModel.request(.push(GitPushOptions(remote: remote.name, setsUpstream: true))) }
                    }

                }
                Divider()
                Button("Force push with lease…") { self.viewModel.request(.push(GitPushOptions(forceWithLease: true))) }
                    .disabled(self.viewModel.snapshot?.upstream == nil)

            } label: {
                Label("Push", systemImage: "arrow.up")
            }

        }
        .disabled(!self.viewModel.canMutate || (self.viewModel.snapshot?.remotes.isEmpty ?? true))
        .help(self.viewModel.runtime.isLive ? "Git uses this Mac's existing remote credentials." : "Git actions are available in Diffy Live.")

    }

}
