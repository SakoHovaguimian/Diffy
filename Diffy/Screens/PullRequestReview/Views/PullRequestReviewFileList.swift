import SwiftUI

struct PullRequestReviewFileList: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel

    var body: some View {

        ScrollViewReader { proxy in

            ScrollView {

                LazyVStack(spacing: 16) {

                    ForEach(self.viewModel.reviewEntries) { entry in

                        if let file = entry.file, let fileViewModel = self.viewModel.reviewFile(for: file.id) {
                            PullRequestReviewFileRow(
                                fileViewModel: fileViewModel,
                                viewModel: self.viewModel,
                                workspace: self.workspace,
                                navigateToLine: { proxy.scrollTo($0, anchor: .center) }
                            )
                            .id(file.id)
                        } else if entry.file == nil {
                            FileNavigatorGroupRow(entry: entry, viewModel: self.viewModel.fileNavigator)
                        }

                    }

                    if self.viewModel.visibleFiles.count > self.viewModel.visibleLimit {
                        Button("Show More Files") { self.viewModel.visibleLimit += 50 }
                            .padding(16)
                    }

                }
                .padding(24)

            }
            .onAppear {
                if let id = self.viewModel.selectedFileID { proxy.scrollTo(id, anchor: .top) }
            }
            .onChange(of: self.viewModel.selectedFileID) { _, id in
                if let id { proxy.scrollTo(id, anchor: .top) }
            }

        }

    }

}
