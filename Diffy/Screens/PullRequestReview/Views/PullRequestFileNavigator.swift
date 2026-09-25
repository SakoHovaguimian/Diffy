import SwiftUI

struct PullRequestFileNavigator: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var navigator: FileNavigatorViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            searchField()
            options()
            Text("\(self.viewModel.viewedPaths.count) / \(self.viewModel.details?.files.count ?? 0) Viewed Locally")
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

                        Text("No Matching Files").font(.system(size: 12))
                        Button("Clear Filters") { self.navigator.clearFilters() }

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

            TextField("Filter Files", text: self.$navigator.query)
                .textFieldStyle(.roundedBorder)
            if !self.navigator.query.isEmpty {

                Button { self.navigator.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear File Search")

            }

        }
        .padding([.horizontal, .top], 12)

    }

    private func options() -> some View {

        HStack(spacing: 7) {

            Menu {

                Picker("Layout", selection: self.$navigator.layout) {
                    ForEach(FileListLayout.allCases) { Text($0.displayName).tag($0) }
                }
                Divider()
                Button("Expand All") { self.navigator.collapsedGroups.removeAll() }
                Button("Collapse All") {

                    self.navigator.collapsedGroups.removeAll()
                    self.navigator.collapsedGroups = Set(self.navigator.entries(self.viewModel.navigationFiles, mode: .pullRequests).filter { $0.file == nil }.map(\.id))

                }

            } label: {
                Label(self.navigator.layout == .tree ? "Tree" : self.navigator.layout.displayName, systemImage: "list.bullet.indent")
            }
            .help("Choose File Layout & Expand Folders")
            Menu {

                Picker("Sort By", selection: self.$navigator.sort) {

                    ForEach(FileSortOrder.allCases) { order in
                        Text(order.displayName).tag(order).disabled(order == .updated || order == .size)
                    }

                }
                Toggle("Reverse Order", isOn: Binding(get: { !self.navigator.ascending }, set: { self.navigator.ascending = !$0 }))
                Divider()
                Text("Disk edit times and file sizes are unavailable for GitHub patches.")

            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort Files")
            .help("Sort Files · \(self.navigator.sort.displayName)")

        }
        .controlSize(.small)
        .padding(.horizontal, 12)

    }

    private func folderRow(_ entry: FileTreeEntry) -> some View {

        Button { self.navigator.toggleGroup(entry.id) } label: {

            HStack(spacing: 6) {

                Image(systemName: self.navigator.collapsedGroups.contains(entry.id) ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9))
                DiffyPathIcon(
                    path: entry.title,
                    isFolder: true,
                    isExpanded: !self.navigator.collapsedGroups.contains(entry.id)
                )
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
        .accessibilityLabel("\(entry.title), \(entry.count) Files")
        .accessibilityValue(self.navigator.collapsedGroups.contains(entry.id) ? "Collapsed" : "Expanded")
        .help(entry.id)

    }

    private func fileRow(_ file: DiffFile, depth: Int) -> some View {

        Button {
            self.viewModel.selectFile(self.viewModel.details?.files.first { $0.id == file.id })
        } label: {

            HStack(alignment: .top, spacing: 8) {

                DiffFileIcon(file: file)
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
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(self.theme.added)
                    .opacity(self.viewModel.viewedPaths.contains(file.id) ? 1 : 0)
                    .accessibilityHidden(true)

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
        .accessibilityValue(self.viewModel.viewedPaths.contains(file.id) ? "Viewed" : "Not Viewed")
        .accessibilityAddTraits(self.viewModel.selectedFileID == file.id ? .isSelected : [])

    }

}
