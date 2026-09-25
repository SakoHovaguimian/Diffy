import SwiftUI

struct RepositoryWorkspaceScreen: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {

        VStack(spacing: 0) {

            RepositoryActionBar(viewModel: self.viewModel)

            if let error = self.viewModel.errorMessage {
                DiffyStatusBanner(message: error, isError: true).padding([.horizontal, .top], 16)
            } else if let notice = self.viewModel.notice {
                DiffyStatusBanner(message: notice).padding([.horizontal, .top], 16)
            }

            if self.viewModel.snapshot == nil && self.viewModel.isRefreshing {
                DiffyLoadingState(title: "Opening Repository…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !self.workspace.showsDashboard && self.workspace.mode == .folders {
                RepositoryFoldersView(viewModel: self.viewModel)
            } else if self.viewModel.snapshot == nil {
                unavailableRepository()
            } else if self.workspace.showsDashboard {
                RepositoryOverviewView(viewModel: self.viewModel, selectMode: self.workspace.selectMode)
            } else {
                page()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(self.theme.background)
        .onAppear {

            if !self.workspace.showsDashboard { self.viewModel.activate(self.workspace.mode) }

        }
        .onChange(of: self.workspace.mode) { _, mode in self.viewModel.activate(mode) }
        .onChange(of: self.workspace.showsDashboard) { _, dashboard in

            self.viewModel.activate(dashboard ? .workingTree : self.workspace.mode)

        }
        .onChange(of: self.scenePhase) { _, phase in

            if phase == .active { Task { await self.viewModel.refresh() } }

        }
        .confirmationDialog(self.viewModel.pendingAction.map { "\($0.request.title) In \($0.projectName)?" } ?? "Git Action", isPresented: Binding(
            get: { self.viewModel.pendingAction != nil },
            set: { if !$0 { self.viewModel.pendingAction = nil } }
        ), titleVisibility: .visible) {

            Button(self.viewModel.pendingAction?.request.title ?? "Continue", role: .destructive) { self.viewModel.confirmAction() }
            Button("Cancel", role: .cancel) { self.viewModel.pendingAction = nil }

        } message: {
            Text(self.viewModel.pendingAction?.consequence ?? "")
        }
        .sheet(item: self.$viewModel.comparisonReview) { request in

            ComparisonReviewScreen(
                viewModel: self.viewModel.reviewViewModel(for: request),
                workspace: self.workspace
            )
            .diffyStyle()
            .diffyContentSize(self.workspace.contentSizeScale)

        }
        .sheet(isPresented: self.$viewModel.showsPatch) {

            VStack(spacing: 0) {

                HStack {

                    Text(self.viewModel.patchTitle).font(.headline)
                    Spacer()
                    Button { self.viewModel.showsPatch = false } label: {
                        Label("Close", systemImage: "xmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.cancelAction)

                }
                .padding(20)
                RepositoryPatchView(viewModel: self.viewModel)

            }
            .frame(minWidth: 800, idealWidth: 1280, maxWidth: .infinity, minHeight: 500, idealHeight: 800, maxHeight: .infinity)
            .background(ComparisonModalSizingView())
            .diffyStyle()

        }

    }

    @ViewBuilder
    private func page() -> some View {

        switch self.workspace.mode {

        case .workingTree, .staged: RepositoryChangesView(viewModel: self.viewModel, workspace: self.workspace)
        case .branches: RepositoryBranchesView(viewModel: self.viewModel)
        case .commits: RepositoryCommitsView(viewModel: self.viewModel)
        case .history: RepositoryHistoryView(viewModel: self.viewModel)
        case .pullRequests: RepositoryPullRequestsView(viewModel: self.viewModel)
        case .merge: RepositoryConflictsView(viewModel: self.viewModel)
        case .folders: RepositoryFoldersView(viewModel: self.viewModel)

        }

    }

    private func unavailableRepository() -> some View {

        VStack(spacing: 16) {

            DiffyEmptyState(symbol: "folder", title: "A Place For Your Project", message: "Git pages require a local checkout. Choose the repository's folder, or clone it from Settings → Accounts.")
            HStack {

                Button("Locate Folder…") {

                    guard let directory = ProjectDirectoryController().chooseDirectory() else { return }
                    self.workspace.relocateSelectedProject(to: directory)

                }
                SettingsLink { Text("Accounts Settings") }
                Button("Retry") { Task { await self.viewModel.refresh() } }

            }
            .padding(.bottom, 32)

        }

    }

}

#Preview {

    let workspace = mockResolve(WorkspaceViewModel.self)
    RepositoryWorkspaceScreen(viewModel: workspace.repositoryViewModel, workspace: workspace)
        .frame(width: 1080, height: 720)
        .withMockPreviews()
        .task { await workspace.repositoryViewModel.load(workspace.project) }

}
