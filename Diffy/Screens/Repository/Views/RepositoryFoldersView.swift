import SwiftUI

struct RepositoryFoldersView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 26) {

                DiffyPageHeading(eyebrow: "Folder Comparison", title: "Two Folders. One Clear Picture.", detail: "Choose an original and an updated folder to inspect a read-only comparison, including files outside Git.")
                HStack(spacing: 16) {

                    folderPicker(title: "Original", url: self.viewModel.leftFolder) {
                        self.viewModel.leftFolder = ProjectDirectoryController().chooseDirectory()
                    }
                    Image(systemName: "arrow.right").foregroundStyle(self.theme.secondaryText)
                    folderPicker(title: "Updated", url: self.viewModel.rightFolder) {
                        self.viewModel.rightFolder = ProjectDirectoryController().chooseDirectory()
                    }

                }
                HStack {

                    Text("Compares every file under the selected folders, including hidden files. Choose source folders to exclude repository internals or build output.")
                        .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
                    Spacer()
                    Button("Compare Folders") { self.viewModel.compareFolders() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!self.viewModel.runtime.isLive || self.viewModel.leftFolder == nil || self.viewModel.rightFolder == nil || self.viewModel.isLoadingPatch)

                }
                Divider()
                Text("Selected Folder Contents · \(self.viewModel.folderEntries.count) Files")
                    .font(.system(size: 16, weight: .semibold))
                if self.viewModel.folderEntries.isEmpty {
                    Text("Compare two folders to browse every file in their combined contents.")
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.secondaryText)
                } else {
                    RepositoryPathNavigation(
                        entries: self.viewModel.folderEntries,
                        selectedPath: self.viewModel.selectedFolderPath,
                        onSelect: self.viewModel.inspectFolderFile,
                        query: self.$viewModel.search,
                        layout: self.$viewModel.folderLayout,
                        sort: self.$viewModel.folderSort,
                        expandedFolders: self.$viewModel.folderExpandedFolders
                    )
                    .frame(minHeight: 300)
                }

            }
            .padding(32)

        }

    }

    private func folderPicker(title: String, url: URL?, action: @escaping () -> Void) -> some View {

        Button(action: action) {

            VStack(alignment: .leading, spacing: 14) {

                HStack {

                    Image(systemName: "folder").font(.system(size: 24)).foregroundStyle(self.theme.accent)
                    Spacer()
                    Image(systemName: "plus.circle").foregroundStyle(self.theme.secondaryText)

                }
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(url?.path ?? "Choose A Folder…")
                    .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
                    .lineLimit(2).truncationMode(.middle)

            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

        }
        .buttonStyle(.plain)
        .disabled(!self.viewModel.runtime.isLive)

    }

}
