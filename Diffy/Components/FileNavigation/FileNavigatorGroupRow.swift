import SwiftUI

struct FileNavigatorGroupRow: View {

    let entry: FileTreeEntry
    @ObservedObject var viewModel: FileNavigatorViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        Button {
            self.viewModel.toggleGroup(entry.id)
        } label: {

            HStack(spacing: self.contentSize.scaled(8)) {

                Image(systemName: self.viewModel.collapsedGroups.contains(entry.id) ? "chevron.right" : "chevron.down")
                    .font(self.contentSize.font(size: 8, weight: .semibold))
                    .frame(width: self.contentSize.scaled(12))
                DiffyPathIcon(
                    path: entry.title,
                    isFolder: true,
                    isExpanded: !self.viewModel.collapsedGroups.contains(entry.id)
                )
                Text(entry.title)
                    .font(self.contentSize.font(size: 11, weight: .semibold))
                Spacer()
                Text("\(entry.count)")
                    .font(self.contentSize.font(size: 9, design: .monospaced))
                    .padding(.horizontal, self.contentSize.scaled(6))
                    .padding(.vertical, self.contentSize.scaled(2))
                    .background(self.theme.surface, in: Capsule())

            }
            .foregroundStyle(self.theme.isDark ? self.theme.secondaryText : self.theme.text)
            .padding(.leading, self.contentSize.scaled(CGFloat(entry.depth) * 15 + 8))
            .padding(.trailing, self.contentSize.scaled(8))
            .padding(.vertical, self.contentSize.scaled(10))
            .background(self.theme.elevated.opacity(self.theme.isDark ? 0.75 : 1), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(8)))
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .help(self.viewModel.collapsedGroups.contains(entry.id) ? "Expand \(entry.title)" : "Collapse \(entry.title)")

    }

}
