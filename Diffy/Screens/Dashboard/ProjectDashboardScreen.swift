import SwiftUI

struct ProjectDashboardScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        if let directoryPath = self.workspace.project.directoryPath {

            localProjectOverview(directoryPath: directoryPath)

        } else {

            ScrollView {

                VStack(alignment: .leading, spacing: 32) {

                    introduction()
                    changeSummary()

                    HStack(alignment: .top, spacing: 36) {

                        recentCommits().frame(maxWidth: .infinity, alignment: .leading)
                        branchList().frame(width: 240, alignment: .leading)

                    }

                    recentlyChanged()

                }
                .padding(32)
                .frame(maxWidth: 1100, alignment: .leading)
                .frame(maxWidth: .infinity)

            }
            .background(self.theme.background)

        }

    }

    private func localProjectOverview(directoryPath: String) -> some View {

        VStack(alignment: .leading, spacing: 20) {

            Image(systemName: self.workspace.project.symbol)
                .font(.system(size: 30))
                .foregroundStyle(self.workspace.bucket(for: self.workspace.project).map { Color(hex: $0.accentHex) } ?? self.theme.accent)

            Text(self.workspace.project.name)
                .font(.system(size: 28, weight: .semibold))

            Text(directoryPath)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(self.theme.secondaryText)
                .textSelection(.enabled)

            Text("This folder is saved in Diffy. File and Git comparisons for added folders are coming in a later milestone.")
                .font(.system(size: 13))
                .foregroundStyle(self.theme.secondaryText)

            Spacer()

        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(self.theme.background)

    }

    private func introduction() -> some View {

        VStack(alignment: .leading, spacing: 9) {

            Text("A clearer view of your work.")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.8)

            Text("Your latest changes, all in one place. Pick up where you left off.")
                .font(.system(size: 13))
                .foregroundStyle(self.theme.secondaryText)

            HStack(spacing: 8) {

                Image(systemName: "arrow.triangle.branch")
                Text(self.workspace.project.branch)
                Circle().fill(self.theme.modified).frame(width: 5, height: 5)
                Text("Uncommitted changes")
                    .foregroundStyle(self.theme.secondaryText)

            }
            .font(.system(size: 11))
            .padding(.top, 12)

        }

    }

    private func changeSummary() -> some View {

        HStack(spacing: 1) {

            summaryCell("Working tree", count: self.workspace.project.files.filter { !$0.isStaged && $0.status != .identical }.count, subtitle: "Ready for a closer look", color: self.theme.accent, mode: .workingTree)
            summaryCell("Staged changes", count: self.workspace.project.files.filter(\.isStaged).count, subtitle: "Prepared for your next commit", color: self.theme.added, mode: .staged)
            summaryCell("Merge conflicts", count: self.workspace.project.files.filter { $0.status == .conflicted }.count, subtitle: "A decision waiting to be made", color: self.theme.modified, mode: .merge)

        }
        .background(self.theme.border)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

    }

    private func summaryCell(_ title: String, count: Int, subtitle: String, color: Color, mode: ComparisonMode) -> some View {

        Button {
            self.workspace.selectMode(mode)
        } label: {

            VStack(alignment: .leading, spacing: 14) {

                HStack {

                    Text(title).font(.system(size: 12, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 10))

                }

                Text("\(count)")
                    .font(.system(size: 34, weight: .light, design: .rounded))
                    .foregroundStyle(color)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                    .lineLimit(2)

            }
            .padding(23)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.theme.surface)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)

    }

    private func recentCommits() -> some View {

        VStack(alignment: .leading, spacing: 18) {

            sectionTitle("Recent commits", detail: "A little progress, every day")

            ForEach(Array(self.workspace.project.commits.enumerated()), id: \.element.id) { index, commit in

                Button {

                    self.workspace.selectMode(.commits)
                    self.workspace.comparisonRight = commit.id

                } label: {

                    HStack(alignment: .top, spacing: 13) {

                        VStack(spacing: 5) {

                            Circle().stroke(index == 0 ? self.theme.accent : self.theme.border, lineWidth: 2).frame(width: 9, height: 9)

                            if index < self.workspace.project.commits.count - 1 {
                                self.theme.border.frame(width: 1, height: 30)
                            }

                        }
                        .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 7) {

                            Text(commit.title)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(2)

                            HStack(spacing: 8) {

                                Text(commit.id).font(.system(size: 10, design: .monospaced)).foregroundStyle(self.theme.accent)
                                Text("\(commit.author) · \(commit.date)").font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)

                            }

                        }

                    }

                }
                .buttonStyle(.plain)
                .help("Show commit \(commit.id) placeholder")

            }

        }

    }

    private func branchList() -> some View {

        VStack(alignment: .leading, spacing: 16) {

            sectionTitle("Branches", detail: "Three paths forward")

            ForEach(["feature/refine-the-details", "main", "develop"], id: \.self) { branch in

                Button {

                    self.workspace.selectMode(.branches)
                    self.workspace.comparisonRight = branch

                } label: {

                    Label(branch, systemImage: "arrow.triangle.branch")
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundStyle(branch == self.workspace.project.branch ? self.theme.accent : self.theme.secondaryText)

                }
                .buttonStyle(.plain)
                .help("Show \(branch) placeholder")

            }

            Divider().padding(.vertical, 8)
            Text("TAGS").font(.system(size: 9, weight: .semibold)).tracking(1).foregroundStyle(self.theme.secondaryText)

            HStack {

                DiffyBadge(title: "v1.4.0", color: self.theme.secondaryText)
                DiffyBadge(title: "v1.3.2", color: self.theme.secondaryText)

            }

        }

    }

    private func recentlyChanged() -> some View {

        VStack(alignment: .leading, spacing: 16) {

            sectionTitle("Freshly changed", detail: "Sorted by last edited on disk · sample dates")

            ForEach(self.workspace.project.files.sorted { $0.updatedMinutesAgo < $1.updatedMinutesAgo }.prefix(4)) { file in

                Button {
                    self.workspace.selectFile(file)
                } label: {

                    HStack(spacing: 12) {

                        DiffFileIcon(file: file, size: 13)
                        Text(file.path).font(.system(size: 11)).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Text("\(file.updatedMinutesAgo)m ago").font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)
                        Image(systemName: file.status.symbol).foregroundStyle(file.status.color(in: self.theme)).frame(width: 12)

                    }
                    .padding(.vertical, 9)

                }
                .buttonStyle(.plain)
                .help("Open \(file.path) in Working Tree")

            }

        }

    }

    private func sectionTitle(_ title: String, detail: String) -> some View {

        VStack(alignment: .leading, spacing: 5) {

            Text(title).font(.system(size: 15, weight: .semibold))
            Text(detail).font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)

        }

    }

}

#Preview {

    ProjectDashboardScreen(
        workspace: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 1080, height: 720)
    .withMockPreviews()

}
