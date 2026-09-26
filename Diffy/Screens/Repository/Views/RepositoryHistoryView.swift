import SwiftUI

struct RepositoryHistoryView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        GeometryReader { geometry in

            HStack(spacing: 0) {

                RepositoryHistoryFileNavigator(viewModel: self.viewModel)
                    .frame(width: min(self.viewModel.historyNavigatorWidth, navigatorMaximumWidth(in: geometry.size.width)))
                HorizontalResizeHandle(
                    label: "Drag To Resize Project Files",
                    resizeGesture: navigatorResizeGesture(availableWidth: geometry.size.width)
                )
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

                        LazyVStack(alignment: .leading, spacing: 0) {

                            ForEach(Array(self.viewModel.history.enumerated()), id: \.element.id) { index, commit in
                                RepositoryCommitRow(commit: commit, showsConnector: index < self.viewModel.history.count - 1, showsPreviousConnector: index > 0) { self.viewModel.inspectCommit(commit) }
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

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

    }

    private func navigatorMaximumWidth(in availableWidth: CGFloat) -> CGFloat {
        min(400, max(240, availableWidth - 340))
    }

    private func navigatorResizeGesture(availableWidth: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                self.viewModel.resizeHistoryNavigator(by: value.translation.width, maximumWidth: navigatorMaximumWidth(in: availableWidth))
            }
            .onEnded { _ in
                self.viewModel.finishResizingHistoryNavigator()
            }

    }

}
