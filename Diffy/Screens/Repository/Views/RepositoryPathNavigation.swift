import SwiftUI

struct RepositoryPathNavigation: View {

    let entries: [RepositoryPathEntry]
    let selectedPath: String?
    let onSelect: (String) -> Void
    @Binding var query: String
    @Binding var layout: RepositoryFileLayout
    @Binding var sort: RepositoryFileSort
    @Binding var expandedFolders: Set<String>
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 8) {

                TextField("Find files", text: self.$query)
                    .textFieldStyle(.roundedBorder)
                if !self.query.isEmpty {
                    Button("Clear") { self.query = "" }
                }

            }

            HStack(spacing: 10) {

                Picker("View", selection: self.$layout) {
                    ForEach(RepositoryFileLayout.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)

                Picker("Sort", selection: self.$sort) {
                    ForEach(RepositoryFileSort.allCases) { Text($0.rawValue).tag($0) }
                }
                .frame(maxWidth: 180)

            }
            .controlSize(.small)

            ScrollView {

                LazyVStack(alignment: .leading, spacing: 2) {

                    ForEach(visibleRows) { row in

                        Button {
                            if row.isFolder {
                                if !self.expandedFolders.insert(row.path).inserted {
                                    self.expandedFolders.remove(row.path)
                                }
                            } else {
                                self.onSelect(row.path)
                            }
                        } label: {

                            HStack(alignment: .top, spacing: 8) {

                                Image(systemName: row.isFolder ? ((self.expandedFolders.contains(row.path) || !self.query.isEmpty) ? "chevron.down" : "chevron.right") : "doc.text")
                                    .font(.system(size: 10))
                                    .frame(width: 13)
                                    .foregroundStyle(self.theme.secondaryText)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(row.title)
                                        .font(.system(size: 11, weight: row.isFolder ? .semibold : .regular))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if let label = row.updateLabel {
                                        Text(label).font(.system(size: 9)).foregroundStyle(self.theme.secondaryText).lineLimit(1)
                                    }
                                }
                                Spacer(minLength: 0)
                                if let status = row.status, status != .identical {
                                    Text(status.rawValue)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(status.color(in: self.theme))
                                }

                            }
                            .padding(.leading, CGFloat(row.depth) * 14)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(self.selectedPath == row.path && !row.isFolder ? self.theme.selection : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                            .contentShape(Rectangle())

                        }
                        .buttonStyle(.plain)

                    }

                }

            }

        }

    }

    private var visibleRows: [PathRow] {

        let matching = self.entries.filter { self.query.isEmpty || $0.path.localizedStandardContains(self.query) }

        if self.layout == .flat {
            return ordered(matching).map { PathRow(path: $0.path, title: $0.path, depth: 0, isFolder: false, updateLabel: $0.updateLabel, date: $0.lastUpdatedAt, status: $0.status) }
        }

        var directories: Set<String> = []
        for entry in matching {
            let parts = entry.path.split(separator: "/")
            for count in 1..<parts.count {
                directories.insert(parts.prefix(count).joined(separator: "/"))
            }
        }

        let folderRows = directories.map { path in
            PathRow(path: path, title: (path as NSString).lastPathComponent, depth: path.split(separator: "/").count - 1, isFolder: true, updateLabel: nil, date: matching.filter { $0.path.hasPrefix(path + "/") }.compactMap(\.lastUpdatedAt).max(), status: nil)
        }
        let fileRows = matching.map { entry in
            PathRow(path: entry.path, title: (entry.path as NSString).lastPathComponent, depth: entry.path.split(separator: "/").count - 1, isFolder: false, updateLabel: entry.updateLabel, date: entry.lastUpdatedAt, status: entry.status)
        }
        let all = folderRows + fileRows
        var rows: [PathRow] = []
        appendChildren(parent: "", all: all, into: &rows)
        return rows

    }

    private func appendChildren(parent: String, all: [PathRow], into rows: inout [PathRow]) {

        let children = all.filter { ($0.path as NSString).deletingLastPathComponent == parent }
        let sorted = children.sorted { left, right in

            if self.sort == .lastUpdated, left.date != right.date {
                return (left.date ?? .distantPast) > (right.date ?? .distantPast)
            }

            if left.isFolder != right.isFolder { return left.isFolder }
            return left.title.localizedStandardCompare(right.title) == .orderedAscending

        }

        for child in sorted {
            rows.append(child)
            if child.isFolder && (self.expandedFolders.contains(child.path) || !self.query.isEmpty) {
                appendChildren(parent: child.path, all: all, into: &rows)
            }
        }

    }

    private func ordered(_ entries: [RepositoryPathEntry]) -> [RepositoryPathEntry] {

        entries.sorted { left, right in

            if self.sort == .lastUpdated, left.lastUpdatedAt != right.lastUpdatedAt {
                return (left.lastUpdatedAt ?? .distantPast) > (right.lastUpdatedAt ?? .distantPast)
            }

            return left.path.localizedStandardCompare(right.path) == .orderedAscending

        }

    }
}

private struct PathRow: Identifiable {
    let path: String
    let title: String
    let depth: Int
    let isFolder: Bool
    let updateLabel: String?
    let date: Date?
    let status: FileChangeStatus?

    var id: String { (self.isFolder ? "folder:" : "file:") + self.path }
}
