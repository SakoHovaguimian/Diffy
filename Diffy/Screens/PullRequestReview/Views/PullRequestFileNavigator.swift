import SwiftUI

struct PullRequestFileNavigator: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var navigator: FileNavigatorViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            searchField()
            options()
            Text("\(self.viewModel.viewedPaths.count) / \(self.viewModel.details?.files.count ?? 0) viewed locally")
                .font(.system(size: 11))
                .foregroundStyle(self.theme.secondaryText)
                .padding(.horizontal, 12)
            ScrollView {

                LazyVStack(spacing: 2) {

                    ForEach(self.navigator.entries(self.viewModel.navigationFiles, mode: .pullRequests)) { entry in

                        if let file = entry.file {
                            fileRow(file, depth: entry.depth)
                        } else {
                            folderRow(entry)
                        }

                    }
                    if self.viewModel.visibleFiles.isEmpty {

                        Text("No matching files").font(.system(size: 12))
                        Button("Clear filters") { self.navigator.clearFilters() }

                    }

                }
                .padding(.horizontal, 6)

            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(self.theme.surface)

    }

    private func searchField() -> some View {

        HStack(spacing: 6) {

            TextField("Filter files", text: self.$navigator.query)
                .textFieldStyle(.roundedBorder)
            if !self.navigator.query.isEmpty {

                Button { self.navigator.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear file search")

            }

        }
        .padding([.horizontal, .top], 12)

    }

    private func options() -> some View {

        HStack(spacing: 7) {

            Menu {

                Picker("Layout", selection: self.$navigator.layout) {
                    ForEach(FileListLayout.allCases) { Text($0.rawValue).tag($0) }
                }
                Divider()
                Button("Expand all") { self.navigator.collapsedGroups.removeAll() }
                Button("Collapse all") {

                    self.navigator.collapsedGroups.removeAll()
                    self.navigator.collapsedGroups = Set(self.navigator.entries(self.viewModel.navigationFiles, mode: .pullRequests).filter { $0.file == nil }.map(\.id))

                }

            } label: {
                Label(self.navigator.layout == .tree ? "Tree" : self.navigator.layout.rawValue, systemImage: "list.bullet.indent")
            }
            .help("Choose file layout and expand folders")
            Menu {

                Picker("Sort by", selection: self.$navigator.sort) {

                    ForEach(FileSortOrder.allCases) { order in
                        Text(order.rawValue).tag(order).disabled(order == .updated || order == .size)
                    }

                }
                Toggle("Reverse order", isOn: Binding(get: { !self.navigator.ascending }, set: { self.navigator.ascending = !$0 }))
                Divider()
                Text("Disk edit times and file sizes are unavailable for GitHub patches.")

            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort files")
            .help("Sort files · \(self.navigator.sort.rawValue)")

        }
        .controlSize(.small)
        .padding(.horizontal, 12)

    }

    private func folderRow(_ entry: FileTreeEntry) -> some View {

        Button { self.navigator.toggleGroup(entry.id) } label: {

            HStack(spacing: 6) {

                Image(systemName: self.navigator.collapsedGroups.contains(entry.id) ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9))
                Image(systemName: "folder")
                Text(entry.title).lineLimit(1)
                Spacer(minLength: 0)
                Text(entry.count.formatted()).foregroundStyle(self.theme.secondaryText)

            }
            .font(.system(size: 11, weight: .medium))
            .padding(.vertical, 8)
            .padding(.leading, CGFloat(entry.depth) * 14 + 10)
            .padding(.trailing, 10)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.title), \(entry.count) files")
        .accessibilityValue(self.navigator.collapsedGroups.contains(entry.id) ? "Collapsed" : "Expanded")
        .help(entry.id)

    }

    private func fileRow(_ file: DiffFile, depth: Int) -> some View {

        Button {
            self.viewModel.selectFile(self.viewModel.details?.files.first { $0.id == file.id })
        } label: {

            HStack(alignment: .top, spacing: 8) {

                Image(systemName: self.viewModel.viewedPaths.contains(file.id) ? "checkmark.circle.fill" : "doc")
                    .foregroundStyle(self.viewModel.viewedPaths.contains(file.id) ? self.theme.added : self.theme.secondaryText)
                VStack(alignment: .leading, spacing: 5) {

                    Text(file.name).font(.system(size: 11, weight: .medium)).lineLimit(1)
                    if self.navigator.layout != .tree, !file.directory.isEmpty {
                        Text(file.directory).font(.system(size: 10)).foregroundStyle(self.theme.secondaryText).lineLimit(1)
                    }
                    HStack(spacing: 6) {

                        Text(file.status.rawValue).foregroundStyle(self.theme.secondaryText)
                        Text("+\(file.additions)").foregroundStyle(self.theme.added)
                        Text("−\(file.deletions)").foregroundStyle(self.theme.removed)

                    }
                    .font(.system(size: 10, design: .monospaced))

                }
                Spacer(minLength: 0)

            }
            .padding(.vertical, 10)
            .padding(.leading, CGFloat(depth) * 14 + 10)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(self.viewModel.selectedFileID == file.id ? self.theme.selection : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .help(file.path)
        .accessibilityLabel(file.path)
        .accessibilityAddTraits(self.viewModel.selectedFileID == file.id ? .isSelected : [])

    }

}
