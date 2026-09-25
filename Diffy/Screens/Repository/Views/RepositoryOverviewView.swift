import SwiftUI

struct RepositoryOverviewView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    let selectMode: (ComparisonMode) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            if let snapshot = self.viewModel.snapshot {

                VStack(alignment: .leading, spacing: 30) {

                    DiffyPageHeading(eyebrow: snapshot.isClean ? "Up to date locally" : "In progress", title: snapshot.isClean ? "Room for your next idea." : "Your next commit starts here.", detail: snapshot.isClean ? "Your working tree is clean. Explore the history or fetch to check for remote updates." : "Review the working tree, choose what belongs together, and commit when you're ready.")
                    changeSummary(snapshot)

                    HStack(alignment: .top, spacing: 32) {

                        VStack(alignment: .leading, spacing: 18) {

                            sectionTitle("Latest activity", detail: "The last \(min(5, snapshot.recentCommits.count)) commits")
                            ForEach(Array(snapshot.recentCommits.prefix(5).enumerated()), id: \.element.id) { index, commit in

                                RepositoryCommitRow(commit: commit, showsConnector: index < min(5, snapshot.recentCommits.count) - 1) {

                                    self.viewModel.inspectCommit(commit)

                                }

                            }

                            if snapshot.recentCommits.isEmpty {
                                Text("No commits yet. Stage a file to make the first one.").font(.system(size: 12)).foregroundStyle(self.theme.secondaryText)
                            }

                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        remoteSummary(snapshot).frame(width: 220, alignment: .leading)

                    }
                    Divider()
                    HStack(alignment: .top) {

                        Label(snapshot.location.rootPath, systemImage: "folder")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(self.theme.secondaryText)
                            .textSelection(.enabled)
                        Spacer()
                        Button("Show in Finder") { ExternalLinkController().reveal(snapshot.location.rootPath) }

                    }
                    Text("Updated \(snapshot.capturedAt.formatted(date: .omitted, time: .standard)). Remote counts use locally fetched tracking refs; \(snapshot.lastFetchAt.map { "last fetch recorded \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "fetch time unknown").")
                        .font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)

                }
                .padding(32)
                .frame(maxWidth: 1120, alignment: .leading)
                .frame(maxWidth: .infinity)

            }

        }

    }

    private func changeSummary(_ snapshot: GitRepositorySnapshot) -> some View {

        HStack(spacing: 1) {

            metric("Unstaged", count: snapshot.unstagedChanges.count, detail: "Changes on disk", color: self.theme.accent, mode: .workingTree, lineCounts: self.viewModel.unstagedLineCounts)
            metric("Staged", count: snapshot.stagedChanges.count, detail: "In your next commit", color: self.theme.added, mode: .staged)
            metric("Conflicts", count: snapshot.conflicts.count, detail: "Decisions to make", color: self.theme.modified, mode: .merge)

        }
        .background(self.theme.border)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

    }

    private func metric(_ title: String, count: Int, detail: String, color: Color, mode: ComparisonMode, lineCounts: DiffLineCounts? = nil) -> some View {

        Button { self.selectMode(mode) } label: {

            VStack(alignment: .leading, spacing: 14) {

                HStack {

                    Text(title).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 10))

                }
                HStack(alignment: .firstTextBaseline, spacing: 10) {

                    Text(count, format: .number).font(.system(size: 38, weight: .light, design: .rounded)).foregroundStyle(color)
                    Spacer(minLength: 4)
                    if title == "Unstaged" {
                        if let lineCounts {
                            Text("+\(lineCounts.additions)").foregroundStyle(self.theme.added)
                            Text("−\(lineCounts.deletions)").foregroundStyle(self.theme.removed)
                        } else {
                            Text("Lines unavailable").foregroundStyle(self.theme.secondaryText)
                        }
                    }

                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                Text(detail).font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)

            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.theme.surface)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)

    }

    private func remoteSummary(_ snapshot: GitRepositorySnapshot) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            sectionTitle("Branch position", detail: snapshot.upstream.map { "\($0.name) · \(snapshot.lastFetchAt.map { "last fetched \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "fetch time unknown")" } ?? "No upstream configured")
            if let upstream = snapshot.upstream {
                HStack(spacing: 24) {
                    Label("\(upstream.ahead) ahead", systemImage: "arrow.up")
                    Label("\(upstream.behind) behind", systemImage: "arrow.down")
                }
                .font(.system(size: 12, weight: .medium))
            } else {
                Text("Choose a tracking branch from Pull to see remote position.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
            }
            Divider()
            sectionTitle("References", detail: "\(snapshot.localBranches.count) local branches · \(snapshot.tags.count) tags")

            ForEach(snapshot.tags.prefix(4)) { tag in
                Label(tag.name, systemImage: "tag").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            }

            if snapshot.operation.isInProgress {
                DiffyStatusBanner(message: snapshot.operation.title)
            }

        }

    }

    private func sectionTitle(_ title: String, detail: String) -> some View {

        VStack(alignment: .leading, spacing: 5) {

            Text(title).font(.system(size: 15, weight: .semibold))
            Text(detail).font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)

        }

    }

}
