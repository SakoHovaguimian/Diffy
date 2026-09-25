import SwiftUI

struct PullRequestCommitsView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @State private var selectedCommitID: String?

    private var selectedCommit: PullRequestCommit? {
        self.viewModel.details?.commits.first { $0.id == self.selectedCommitID }
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 20) {

                DiffyPageHeading(
                    eyebrow: "Pull Request History",
                    title: "Commits",
                    detail: "Follow the commits in the order they were added to this pull request."
                )

                if let commits = self.viewModel.details?.commits, !commits.isEmpty {

                    LazyVStack(alignment: .leading, spacing: 0) {

                        ForEach(Array(commits.enumerated()), id: \.element.id) { index, commit in
                            commitRow(commit, showsConnector: index < commits.count - 1)
                        }

                    }
                    .padding(20)
                    .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(self.theme.border) }

                } else {
                    DiffyEmptyState(symbol: "point.topleft.down.to.point.bottomright.curvepath", title: "No Commits Available", message: "Refresh to load the pull request's commit history.")
                }

                if let selectedCommit {
                    commitDetail(selectedCommit)
                }

            }
            .padding(32)
            .frame(maxWidth: 960, alignment: .leading)
            .frame(maxWidth: .infinity)

        }

    }

    private func commitRow(_ commit: PullRequestCommit, showsConnector: Bool) -> some View {

        Button {
            self.selectedCommitID = self.selectedCommitID == commit.id ? nil : commit.id
        } label: {

            HStack(alignment: .top, spacing: 14) {

                VStack(spacing: 5) {

                    Circle()
                        .stroke(self.theme.accent, lineWidth: 2)
                        .frame(width: 9, height: 9)
                    if showsConnector { self.theme.border.frame(width: 1, height: 40) }

                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 7) {

                    Text(commit.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(self.theme.text)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {

                        Text(commit.shortID)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(self.theme.accent)
                        Text(commit.authorName)
                        Text("·")
                        Text(commit.authoredAt, format: .dateTime.month(.abbreviated).day().hour().minute())

                    }
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)

                }
                Spacer(minLength: 0)
                Image(systemName: self.selectedCommitID == commit.id ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 7)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(commit.title), by \(commit.authorName), \(commit.shortID)")

    }

    private func commitDetail(_ commit: PullRequestCommit) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack {

                Text("Commit Details")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if let url = self.viewModel.request.link.webURL?.appendingPathComponent("commit/\(commit.id)") {
                    Link(destination: url) { Label("Open Commit On GitHub", systemImage: "arrow.up.right") }
                }

            }

            Text(commit.message)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
            Text(commit.id)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(self.theme.secondaryText)
                .textSelection(.enabled)

        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(self.theme.border) }

    }
}
