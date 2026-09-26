import SwiftUI

struct FileNavigatorScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var viewModel: FileNavigatorViewModel

    var body: some View {

        FileNavigatorView(
            files: self.workspace.files,
            mode: self.workspace.mode,
            selectedFileID: self.workspace.currentFileID,
            isLoading: self.workspace.runtime.isLive && self.workspace.repositoryViewModel.comparison.isLoadingFiles,
            isLive: self.workspace.runtime.isLive,
            selectFile: { self.workspace.selectFile($0, mode: self.workspace.mode) },
            showFileHistory: self.workspace.showFileHistory,
            viewModel: self.viewModel
        )

    }

}

#Preview {

    let workspace = mockResolve(WorkspaceViewModel.self)

    FileNavigatorScreen(workspace: workspace, viewModel: workspace.fileNavigatorViewModel)
        .frame(width: 260, height: 650)
        .withMockPreviews()

}
