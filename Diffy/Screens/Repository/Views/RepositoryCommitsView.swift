import SwiftUI

struct RepositoryCommitsView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 28) {

                DiffyPageHeading(eyebrow: "Commit History", title: "Every Change Has A Story.", detail: "Browse any branch without checking it out. Open a commit to inspect exactly what it introduced.")
                HStack {

                    RepositoryBranchPicker(
                        branches: self.viewModel.snapshot?.branches ?? [],
                        selection: Binding(
                            get: { self.viewModel.commitsBranch },
                            set: { self.viewModel.selectCommitsBranch($0) }
                        )
                    )
                    Spacer()
                    Text("Latest \(self.viewModel.branchCommits.count) Commits")

                }
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                Divider()
                LazyVStack(alignment: .leading, spacing: 8) {

                    ForEach(Array(self.viewModel.branchCommits.enumerated()), id: \.element.id) { index, commit in
                        RepositoryCommitRow(commit: commit, showsConnector: index < self.viewModel.branchCommits.count - 1) { self.viewModel.inspectCommit(commit) }
                    }

                }

                if self.viewModel.isLoadingCommits {
                    DiffyLoadingState(title: "Reading \(self.viewModel.commitsBranch)…")
                } else if let error = self.viewModel.commitsError {

                    VStack(alignment: .leading, spacing: 12) {

                        DiffyStatusBanner(message: error, isError: true)
                        Button("Retry") { Task { await self.viewModel.loadCommits() } }

                    }

                } else if self.viewModel.branchCommits.isEmpty {
                    DiffyEmptyState(symbol: "clock", title: "No Commits On This Branch", message: "Choose another branch, or make the first commit from your staged changes.")
                }

            }
            .padding(32)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity)

        }

    }

}
