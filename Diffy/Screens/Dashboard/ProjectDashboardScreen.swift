import SwiftUI

struct ProjectDashboardScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel

    var body: some View {
        RepositoryOverviewView(viewModel: self.workspace.repositoryViewModel, selectMode: self.workspace.selectMode)
    }

}

#Preview {

    ProjectDashboardScreen(workspace: mockResolve(WorkspaceViewModel.self))
        .frame(width: 1080, height: 720)
        .withMockPreviews()

}
