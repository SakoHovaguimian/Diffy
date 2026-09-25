import SwiftUI

struct RepositoryChangesToolbar: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var isStaged: Bool { self.workspace.mode == .staged }

    private var visiblePaths: [String] {

        let files = self.workspace.fileNavigatorViewModel.visibleFiles(self.workspace.files, mode: self.workspace.mode)
        return files.filter { $0.status != .conflicted }.map(\.path)

    }

    var body: some View {

        HStack(spacing: self.contentSize.scaled(12)) {

            Text(self.isStaged ? "Staged Changes" : "Working Tree")
                .fontWeight(.medium)
            Spacer()

            Button(self.isStaged ? "Unstage File" : "Stage File") {

                guard let file = self.workspace.file else { return }
                self.viewModel.request(self.isStaged ? .unstage(paths: [file.path]) : .stage(paths: [file.path]))

            }
            .disabled(!self.viewModel.canMutate || self.workspace.file == nil || self.workspace.file?.status == .conflicted)

            Menu {

                Button(self.isStaged ? "Unstage Shown Files" : "Stage Shown Files") {
                    self.viewModel.request(self.isStaged ? .unstage(paths: self.visiblePaths) : .stage(paths: self.visiblePaths))
                }
                .disabled(self.visiblePaths.isEmpty)

                if !self.isStaged, let file = self.workspace.file {

                    Divider()
                    Button("Discard Unstaged Changes…", role: .destructive) {
                        self.viewModel.request(.restore(paths: [file.path]))
                    }
                    .disabled(file.status == .added || file.status == .conflicted)

                }

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: self.contentSize.scaled(20))
            .help("Git File Actions")
            .disabled(!self.viewModel.canMutate)

            Button("Commit…") { self.viewModel.showsCommitComposer = true }
                .disabled(!self.viewModel.canMutate || (self.viewModel.snapshot?.stagedChanges.isEmpty ?? true))
                .popover(isPresented: self.$viewModel.showsCommitComposer) {
                    RepositoryCommitComposer(viewModel: self.viewModel)
                        .frame(width: 340)
                        .diffyStyle()
                }

        }
        .font(self.contentSize.font(size: 11))
        .controlSize(.small)
        .padding(.horizontal, self.contentSize.scaled(16))
        .frame(height: self.contentSize.scaled(40))
        .background(self.theme.surface)
        .disabled(self.viewModel.comparison.isLoadingFiles || self.viewModel.comparison.isLoadingFile)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

}
