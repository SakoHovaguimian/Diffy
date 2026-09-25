import SwiftUI

struct RepositoryFoldersView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 26) {

                DiffyPageHeading(eyebrow: "Folder comparison", title: "Two folders. One clear picture.", detail: "Choose an original and an updated folder to inspect a read-only comparison, including files outside Git.")
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
                    Button("Compare folders") { self.viewModel.compareFolders() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!self.viewModel.runtime.isLive || self.viewModel.leftFolder == nil || self.viewModel.rightFolder == nil || self.viewModel.isLoadingPatch)

                }
                Divider()
                HStack {

                    Text("Tracked files").font(.system(size: 16, weight: .semibold))
                    Text("\(self.viewModel.trackedPaths.count)").font(.system(size: 11, design: .monospaced)).foregroundStyle(self.theme.secondaryText)
                    Spacer()
                    TextField("Filter paths", text: self.$viewModel.search).textFieldStyle(.roundedBorder).frame(maxWidth: 250)
                    if !self.viewModel.search.isEmpty { Button("Clear") { self.viewModel.search = "" } }

                }
                LazyVStack(alignment: .leading, spacing: 0) {

                    ForEach(self.viewModel.visiblePaths.prefix(self.viewModel.visibleLimit), id: \.self) { path in

                        HStack(spacing: 12) {

                            Image(systemName: "doc.text").foregroundStyle(self.theme.accent)
                            Text(path).font(.system(size: 12, design: .monospaced)).textSelection(.enabled)
                            Spacer()

                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

                    }

                }

                if self.viewModel.visiblePaths.count > self.viewModel.visibleLimit {
                    Button("Show more files") { self.viewModel.visibleLimit += 50 }
                } else if self.viewModel.visiblePaths.isEmpty {
                    Text("No tracked files match this filter.").foregroundStyle(self.theme.secondaryText)
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
                Text(url?.path ?? "Choose a folder…")
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
