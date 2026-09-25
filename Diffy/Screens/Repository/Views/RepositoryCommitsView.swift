import SwiftUI

struct RepositoryCommitsView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                DiffyPageHeading(eyebrow: "Commit history", title: "Every change has a story.", detail: "Follow the current branch's history. Open a commit to inspect exactly what it introduced.")
                HStack {

                    Label(self.viewModel.snapshot?.head.displayName ?? "HEAD", systemImage: "arrow.triangle.branch")
                    Spacer()
                    Text("Latest \(self.viewModel.snapshot?.recentCommits.count ?? 0) commits")

                }
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                Divider()
                LazyVStack(alignment: .leading, spacing: 8) {

                    ForEach(Array((self.viewModel.snapshot?.recentCommits ?? []).enumerated()), id: \.element.id) { index, commit in
                        RepositoryCommitRow(commit: commit, showsConnector: index < (self.viewModel.snapshot?.recentCommits.count ?? 0) - 1) { self.viewModel.inspectCommit(commit) }
                    }

                }

                if self.viewModel.snapshot?.recentCommits.isEmpty ?? true {
                    DiffyEmptyState(symbol: "clock", title: "The story starts here", message: "Make the first commit from your staged changes.")
                }

            }
            .padding(32)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity)

        }

    }

}
