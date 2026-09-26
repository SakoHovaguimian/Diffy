import SwiftUI

struct FileNavigatorOptions: View {

    @ObservedObject var viewModel: FileNavigatorViewModel
    let files: [DiffFile]
    let mode: ComparisonMode
    var unavailableSortOrders: Set<FileSortOrder> = []
    var horizontalPadding: CGFloat = 16
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        HStack(spacing: self.contentSize.scaled(7)) {

            Menu {

                Picker("Layout", selection: self.$viewModel.layout) {
                    ForEach(FileListLayout.allCases) { Text($0.displayName).tag($0) }
                }

                Divider()
                Button("Expand All") { self.viewModel.collapsedGroups.removeAll() }
                Button("Collapse All") {
                    self.viewModel.collapseAllGroups(in: self.files, mode: self.mode)
                }

            } label: {
                Label(self.viewModel.layout == .tree ? "Tree" : self.viewModel.layout.displayName, systemImage: "list.bullet.indent")
            }
            .help("Choose File Layout & Expand Folders")

            Menu {

                Picker("Sort By", selection: self.$viewModel.sort) {
                    ForEach(FileSortOrder.allCases) { order in
                        Text(order.displayName).tag(order).disabled(self.unavailableSortOrders.contains(order))
                    }
                }

                Toggle("Reverse Order", isOn: Binding(get: { !self.viewModel.ascending }, set: { self.viewModel.ascending = !$0 }))

            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort Files")
            .help("Sort Files · \(self.viewModel.sort.displayName)")

            Menu {

                Button("All Changes") { self.viewModel.filter = nil }

                ForEach(FileChangeStatus.allCases) { status in
                    Button(status.rawValue) { self.viewModel.filter = status }
                }

            } label: {
                Image(systemName: self.viewModel.filter == nil ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel("Filter Files By Change Status")
            .help("Filter Files By Change Status")

        }
        .menuStyle(.borderlessButton)
        .font(self.contentSize.font(size: 10))
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, self.contentSize.scaled(self.horizontalPadding))
        .padding(.vertical, self.contentSize.scaled(13))
        .overlay(alignment: .bottom) { self.theme.border.frame(height: self.contentSize.scaled(1)) }

    }

}
