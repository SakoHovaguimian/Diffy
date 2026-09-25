import SwiftUI

struct RepositoryChangesView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @ObservedObject var workspace: WorkspaceViewModel

    var body: some View {

        VStack(spacing: 0) {

            RepositoryChangesToolbar(viewModel: self.viewModel, workspace: self.workspace)
            ComparisonScreen(workspace: self.workspace)

        }

    }

}
