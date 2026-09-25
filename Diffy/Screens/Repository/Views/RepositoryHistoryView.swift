import SwiftUI

struct RepositoryHistoryView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HSplitView {

            VStack(alignment: .leading, spacing: 14) {

                Text("Project Files").font(.system(size: 16, weight: .semibold))
                Text(self.inventoryDetail)
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                RepositoryBranchPicker(
                    branches: self.viewModel.snapshot?.branches ?? [],
                    selection: Binding(
                        get: { self.viewModel.historyBranch },
                        set: { self.viewModel.selectHistoryBranch($0) }
                    )
                )
                if self.viewModel.isLoadingHistoryFiles {
                    DiffyLoadingState(title: "Reading Files…")
                } else if let error = self.viewModel.historyFilesError {

                    VStack(alignment: .leading, spacing: 10) {

                        DiffyStatusBanner(message: error, isError: true)
                        Button("Retry") { Task { await self.viewModel.loadPaths() } }

                    }

                } else {
                    RepositoryPathNavigation(
                        entries: self.viewModel.pathEntries,
                        selectedPath: self.viewModel.historyPath,
                        onSelect: { path in Task { await self.viewModel.loadHistory(path: path) } },
                        query: self.$viewModel.search,
                        layout: self.$viewModel.historyLayout,
                        sort: self.$viewModel.historySort,
                        expandedFolders: self.$viewModel.historyExpandedFolders
                    )
                }

            }
            .padding(20)
            .frame(minWidth: 240, idealWidth: 300, maxWidth: 400, maxHeight: .infinity, alignment: .topLeading)
            ScrollView {

                VStack(alignment: .leading, spacing: 26) {

                    DiffyPageHeading(
                        eyebrow: "File History · \(self.viewModel.historyBranch)",
                        title: "A Closer Look Through Time.",
                        detail: self.viewModel.historyPath.isEmpty ? "Choose a file to follow its commits, including renames. Files without Git history remain listed." : self.viewModel.historyPath
                    )

                    if self.viewModel.isLoadingHistory {
                        DiffyLoadingState(title: "Reading History…")
                    } else if self.viewModel.history.isEmpty {
                        DiffyEmptyState(symbol: "clock.arrow.circlepath", title: self.viewModel.historyPath.isEmpty ? "Choose A File" : "No Git History", message: self.viewModel.historyPath.isEmpty ? "Its history on \(self.viewModel.historyBranch) will appear here. Each commit opens a read-only comparison." : "This file has no commits on \(self.viewModel.historyBranch) yet.")
                    }

                    if let error = self.viewModel.patchError {
                        DiffyStatusBanner(message: error, isError: true)
                    }

                    LazyVStack(alignment: .leading, spacing: 8) {

                        ForEach(Array(self.viewModel.history.enumerated()), id: \.element.id) { index, commit in
                            RepositoryCommitRow(commit: commit, showsConnector: index < self.viewModel.history.count - 1) { self.viewModel.inspectCommit(commit) }
                        }

                    }

                    if self.viewModel.history.count == self.viewModel.historyLimit && self.viewModel.historyLimit < 500 {
                        Button("Load Older Commits") { Task { await self.viewModel.loadHistory(path: self.viewModel.historyPath, more: true) } }
                            .disabled(self.viewModel.isLoadingHistory)
                    }

                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            }
            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

    }

}

private extension RepositoryHistoryView {

    var inventoryDetail: String {

        if self.viewModel.browsingRevision(for: self.viewModel.historyBranch) == nil {
            return "Git dates cover the latest 500 commits on this branch. Other files show disk modification time."
        }

        return "Files and Git dates come from this branch. Your working tree stays unchanged."

    }

}
