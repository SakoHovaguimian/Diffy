import SwiftUI

struct PullRequestReviewHeaderView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var aiWorkspace: AIReviewWorkspaceViewModel
    let close: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(alignment: .top, spacing: 20) {

            VStack(alignment: .leading, spacing: 9) {

                Text(self.viewModel.request.link.fullName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)
                Text("#\(self.viewModel.request.number) \(self.viewModel.details?.summary.title ?? self.viewModel.request.title)")
                    .font(.system(size: 23, weight: .semibold))
                    .lineLimit(2)
                    .textSelection(.enabled)
                if let details = self.viewModel.details {
                    metadata(for: details)
                }

            }
            Spacer(minLength: 8)
            Button {
                self.aiWorkspace.openComposer()
            } label: {
                Label("Ask AI", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .popover(isPresented: self.$aiWorkspace.showsComposer, arrowEdge: .bottom) {
                AIReviewComposerView(viewModel: self.aiWorkspace)
                    .diffyStyle()
            }
            Link(destination: self.viewModel.request.webURL) {
                Label("Open In GitHub", systemImage: "arrow.up.right")
            }
            Button("Close", action: self.close)
                .keyboardShortcut(.cancelAction)
                .disabled(self.viewModel.isSubmitting)

        }
        .padding(24)
        .background(self.theme.surface)

    }

    private func metadata(for details: PullRequestReviewDetails) -> some View {

        HStack(spacing: 10) {

            GitHubAvatar(user: details.summary.author, size: 18)
            Text(details.summary.author.login)
            Text("·")
            Text("\(details.commitCount) Commits")
            Text("·")
            if let counts = details.summary.lineCounts {
                Text("+\(counts.additions)").foregroundStyle(self.theme.added)
                Text("−\(counts.deletions)").foregroundStyle(self.theme.removed)
                Text("·")
            }
            DiffyBadge(title: details.summary.statusTitle, color: self.theme.accent)
            Text("·")
            Text("\(details.summary.headRef) → \(details.summary.baseRef)")
                .lineLimit(1)

        }
        .font(.system(size: 11))
        .foregroundStyle(self.theme.secondaryText)

    }
}
