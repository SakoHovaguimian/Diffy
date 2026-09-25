import SwiftUI

struct FileNavigatorScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var viewModel: FileNavigatorViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @State private var hoveredEntryID: String?

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            navigatorHeader()
            searchField()
            navigatorOptions()

            if self.viewModel.entries(self.workspace.project.files, mode: self.workspace.mode).isEmpty {

                VStack(spacing: self.contentSize.scaled(12)) {

                    DiffyEmptyState(symbol: "line.3.horizontal.decrease.circle", title: "No matching files", message: "Try a different name or clear the active filters.")
                    Button("Clear filters") { self.viewModel.clearFilters() }
                        .padding(.bottom, self.contentSize.scaled(24))

                }

            } else {

                ScrollView {

                    LazyVStack(spacing: self.contentSize.scaled(2)) {

                        ForEach(self.viewModel.entries(self.workspace.project.files, mode: self.workspace.mode)) { entry in
                            entryRow(entry)
                        }

                    }
                    .padding(.horizontal, self.contentSize.scaled(8))
                    .padding(.vertical, self.contentSize.scaled(12))

                }

            }

            Spacer(minLength: 0)
            navigatorFooter()

        }
        .background(self.theme.surface)

    }

    private func navigatorHeader() -> some View {

        HStack {

            Text("CHANGED FILES")
                .font(self.contentSize.font(size: 9, weight: .semibold))
                .tracking(self.contentSize.scaled(1.2))

            Spacer()

            Text("\(self.viewModel.visibleFiles(self.workspace.project.files, mode: self.workspace.mode).count)")
                .font(self.contentSize.font(size: 10, design: .monospaced))

        }
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, self.contentSize.scaled(16))
        .padding(.top, self.contentSize.scaled(21))
        .padding(.bottom, self.contentSize.scaled(14))

    }

    private func searchField() -> some View {

        HStack(spacing: self.contentSize.scaled(7)) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(self.theme.secondaryText)
            TextField("Find a file…", text: self.$viewModel.query)
                .textFieldStyle(.plain)

            if !self.viewModel.query.isEmpty {

                Button { self.viewModel.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear file search")
                .help("Clear file search")

            }

        }
        .font(self.contentSize.font(size: 11))
        .padding(self.contentSize.scaled(8))
        .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(6)))
        .padding(.horizontal, self.contentSize.scaled(12))

    }

    private func navigatorOptions() -> some View {

        HStack(spacing: self.contentSize.scaled(7)) {

            Menu {

                Picker("Layout", selection: self.$viewModel.layout) {
                    ForEach(FileListLayout.allCases) { Text($0.rawValue).tag($0) }
                }

                Divider()
                Button("Expand all") { self.viewModel.collapsedGroups.removeAll() }
                Button("Collapse all") {

                    self.viewModel.collapsedGroups = Set(self.viewModel.entries(self.workspace.project.files, mode: self.workspace.mode).filter { $0.file == nil }.map(\.id))

                }

            } label: {
                Label(self.viewModel.layout == .tree ? "Tree" : self.viewModel.layout.rawValue, systemImage: "list.bullet.indent")
            }
            .help("Choose file layout and expand folders")

            Menu {

                Picker("Sort by", selection: self.$viewModel.sort) {
                    ForEach(FileSortOrder.allCases) { Text($0.rawValue).tag($0) }
                }

                Toggle("Reverse order", isOn: Binding(get: { !self.viewModel.ascending }, set: { self.viewModel.ascending = !$0 }))

            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .help("Sort files")

            Menu {

                Button("All changes") { self.viewModel.filter = nil }

                ForEach(FileChangeStatus.allCases) { status in
                    Button(status.rawValue) { self.viewModel.filter = status }
                }

            } label: {
                Image(systemName: self.viewModel.filter == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
            }
            .help("Filter files by change status")

        }
        .menuStyle(.borderlessButton)
        .font(self.contentSize.font(size: 10))
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, self.contentSize.scaled(16))
        .padding(.vertical, self.contentSize.scaled(13))
        .overlay(alignment: .bottom) { self.theme.border.frame(height: self.contentSize.scaled(1)) }

    }

    @ViewBuilder
    private func entryRow(_ entry: FileTreeEntry) -> some View {

        if let file = entry.file {

            Button {
                self.workspace.selectFile(file)
            } label: {

                HStack(spacing: self.contentSize.scaled(9)) {

                    DiffFileIcon(file: file, size: 13)

                    Text(file.name)
                        .font(self.contentSize.font(size: 11))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: self.contentSize.scaled(3))

                    Image(systemName: file.status.symbol)
                        .font(self.contentSize.font(size: 9, weight: .bold))
                        .foregroundStyle(file.status.color(in: self.theme))
                        .frame(width: self.contentSize.scaled(18), height: self.contentSize.scaled(18))
                        .background(file.status.color(in: self.theme).opacity(0.12), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(4)))

                }
                .padding(.leading, self.contentSize.scaled(CGFloat(entry.depth) * 15 + 11))
                .padding(.trailing, self.contentSize.scaled(8))
                .padding(.vertical, self.contentSize.scaled(9))
                .background(
                    self.workspace.selectedFileID == file.id ? self.theme.selection :
                        self.hoveredEntryID == entry.id ? self.theme.elevated : .clear,
                    in: RoundedRectangle(cornerRadius: self.contentSize.scaled(8))
                )
                .overlay(alignment: .leading) {

                    if self.workspace.selectedFileID == file.id {

                        RoundedRectangle(cornerRadius: self.contentSize.scaled(2))
                            .fill(self.theme.accent)
                            .frame(width: self.contentSize.scaled(3))

                    }

                }
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .onHover { hovering in self.hoveredEntryID = hovering ? entry.id : nil }
            .help("\(file.path) · \(file.status.rawValue) · edited \(file.updatedMinutesAgo)m ago")
            .accessibilityLabel("\(file.path), \(file.status.rawValue)")
            .contextMenu {

                Button("Open comparison") { self.workspace.selectFile(file) }
                Button("Copy relative path") { ExportController.copy(file.path) }
                Button("Show file history") {

                    self.workspace.selectFile(file)
                    self.workspace.selectMode(.history)

                }

            }

        } else {

            Button {
                self.viewModel.toggleGroup(entry.id)
            } label: {

                HStack(spacing: self.contentSize.scaled(8)) {

                    Image(systemName: self.viewModel.collapsedGroups.contains(entry.id) ? "chevron.right" : "chevron.down")
                        .font(self.contentSize.font(size: 8, weight: .semibold))
                        .frame(width: self.contentSize.scaled(12))
                    Image(systemName: "folder.fill")
                        .font(self.contentSize.font(size: 12))
                        .foregroundStyle(self.theme.accent.opacity(0.8))
                    Text(entry.title)
                        .font(self.contentSize.font(size: 11, weight: .semibold))
                    Spacer()
                    Text("\(entry.count)")
                        .font(self.contentSize.font(size: 9, design: .monospaced))
                        .padding(.horizontal, self.contentSize.scaled(6))
                        .padding(.vertical, self.contentSize.scaled(2))
                        .background(self.theme.surface, in: Capsule())

                }
                .foregroundStyle(self.theme.secondaryText)
                .padding(.leading, self.contentSize.scaled(CGFloat(entry.depth) * 15 + 8))
                .padding(.trailing, self.contentSize.scaled(8))
                .padding(.vertical, self.contentSize.scaled(10))
                .background(self.theme.elevated.opacity(0.75), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(8)))
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .help(self.viewModel.collapsedGroups.contains(entry.id) ? "Expand \(entry.title)" : "Collapse \(entry.title)")

        }

    }

    private func navigatorFooter() -> some View {

        VStack(alignment: .leading, spacing: self.contentSize.scaled(6)) {

            Label(self.viewModel.sort.rawValue, systemImage: "arrow.up.arrow.down")

            if let filter = self.viewModel.filter {
                Text("Showing \(filter.rawValue.lowercased()) files")
            }

            Text("Dates are fixed sample metadata")
                .font(self.contentSize.font(size: 9))

        }
        .font(self.contentSize.font(size: 10))
        .foregroundStyle(self.theme.secondaryText)
        .padding(self.contentSize.scaled(14))

    }

}

#Preview {

    let workspace = mockResolve(WorkspaceViewModel.self)

    FileNavigatorScreen(
        workspace: workspace,
        viewModel: workspace.fileNavigatorViewModel
    )
    .frame(width: 260, height: 650)
    .withMockPreviews()

}
