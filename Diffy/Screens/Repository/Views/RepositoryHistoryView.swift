import SwiftUI

struct RepositoryHistoryView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HSplitView {

            VStack(alignment: .leading, spacing: 14) {

                Text("Find a file").font(.system(size: 16, weight: .semibold))
                HStack {

                    TextField("Filter tracked files", text: self.$viewModel.search).textFieldStyle(.roundedBorder)
                    if !self.viewModel.search.isEmpty { Button("Clear") { self.viewModel.search = "" } }

                }
                ScrollView {

                    LazyVStack(alignment: .leading, spacing: 0) {

                        ForEach(self.viewModel.visiblePaths.prefix(self.viewModel.visibleLimit), id: \.self) { path in

                            Button { Task { await self.viewModel.loadHistory(path: path) } } label: {
                                Label(path, systemImage: "doc.text")
                                    .font(.system(size: 11))
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(self.viewModel.historyPath == path ? self.theme.selection : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

                        }

                        if self.viewModel.visiblePaths.count > self.viewModel.visibleLimit {
                            Button("Show more files") { self.viewModel.visibleLimit += 50 }.padding(10)
                        }

                    }

                }

            }
            .padding(20)
            .frame(minWidth: 240, idealWidth: 300, maxWidth: 400)
            ScrollView {

                VStack(alignment: .leading, spacing: 26) {

                    DiffyPageHeading(eyebrow: "File history", title: "A closer look through time.", detail: self.viewModel.historyPath.isEmpty ? "Choose a tracked file to follow its commits, including renames." : self.viewModel.historyPath)

                    if self.viewModel.isLoadingHistory {
                        ProgressView("Reading history…")
                    } else if self.viewModel.history.isEmpty {
                        DiffyEmptyState(symbol: "clock.arrow.circlepath", title: "Choose a file", message: "Its history will appear here. Each commit opens a read-only comparison.")
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
                        Button("Load older commits") { Task { await self.viewModel.loadHistory(path: self.viewModel.historyPath, more: true) } }
                            .disabled(self.viewModel.isLoadingHistory)
                    }

                }
                .padding(32)

            }
            .frame(minWidth: 300, maxWidth: .infinity)

        }

    }

}
