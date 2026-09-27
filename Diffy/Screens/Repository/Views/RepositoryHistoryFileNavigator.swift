import SwiftUI

struct RepositoryHistoryFileNavigator: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .diffyStatusAnimation(value: self.viewModel.historyFilesError)

    }

}

private extension RepositoryHistoryFileNavigator {

    var inventoryDetail: String {

        if self.viewModel.browsingRevision(for: self.viewModel.historyBranch) == nil {
            return "Git dates cover the latest 500 commits on this branch. Other files show disk modification time."
        }

        return "Files and Git dates come from this branch. Your working tree stays unchanged."

    }

}
