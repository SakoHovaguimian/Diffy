import SwiftUI
import Combine

@MainActor
final class FileNavigatorViewModel: ViewModel {

    let loggerName = "FILE_NAVIGATOR_VIEW_MODEL"
    private let preferencesService: PreferencesServiceProtocol
    private var projectID = "rune"
    private var isRestoring = false

    @Published var query = ""
    @Published var sort: FileSortOrder = .path {
        didSet { persist() }
    }

    @Published var layout: FileListLayout = .tree {
        didSet { persist() }
    }

    @Published var ascending = true {
        didSet { persist() }
    }

    @Published var filter: FileChangeStatus? {
        didSet { persist() }
    }

    @Published var collapsedGroups: Set<String> = []

    init(preferencesService: PreferencesServiceProtocol) {

        self.preferencesService = preferencesService
        restore(projectID: self.projectID)

    }

    // MARK: - Project Preferences

    func restore(projectID: String) {

        self.isRestoring = true
        self.projectID = projectID

        let preferences = self.preferencesService.load(FileNavigationPreferences.self, key: "navigation.\(projectID)") ?? FileNavigationPreferences()

        self.sort = preferences.sort
        self.layout = preferences.layout
        self.ascending = preferences.ascending
        self.filter = preferences.filter
        self.query = ""
        self.collapsedGroups = []
        self.isRestoring = false

    }

    private func persist() {

        guard !self.isRestoring else {
            return
        }

        let preferences = FileNavigationPreferences(sort: self.sort, layout: self.layout, ascending: self.ascending, filter: self.filter)
        self.preferencesService.save(preferences, key: "navigation.\(self.projectID)")

    }

    // MARK: - Visible Files

    func visibleFiles(_ files: [DiffFile], mode: ComparisonMode) -> [DiffFile] {

        let matchingFiles = filterFiles(files, mode: mode)
        return sortFiles(matchingFiles)

    }

    private func filterFiles(_ files: [DiffFile], mode: ComparisonMode) -> [DiffFile] {

        files.filter { file in

            let matchesQuery = self.query.isEmpty || file.path.localizedCaseInsensitiveContains(self.query)
            let matchesStatus = self.filter == nil || file.status == self.filter
            let matchesStaging = mode != .staged || file.isStaged

            return matchesQuery && matchesStatus && matchesStaging

        }

    }

    private func sortFiles(_ files: [DiffFile]) -> [DiffFile] {

        files.sorted { left, right in

            let order = compare(left, right)
            return self.ascending ? order : compare(right, left)

        }

    }

    private func compare(_ left: DiffFile, _ right: DiffFile) -> Bool {

        switch self.sort {

        case .updated where left.updatedMinutesAgo != right.updatedMinutesAgo:
            return left.updatedMinutesAgo < right.updatedMinutesAgo

        case .changeSize where left.changeMagnitude != right.changeMagnitude:
            return left.changeMagnitude > right.changeMagnitude

        case .size where left.size != right.size:
            return left.size > right.size

        case .status where left.status != right.status:
            return left.status.rawValue < right.status.rawValue

        case .name where left.name != right.name:
            return left.name.localizedStandardCompare(right.name) == .orderedAscending

        case .fileType where left.language != right.language:
            return left.language < right.language

        default:
            return left.path.localizedStandardCompare(right.path) == .orderedAscending

        }

    }

    // MARK: - Tree Presentation

    func entries(_ files: [DiffFile], mode: ComparisonMode) -> [FileTreeEntry] {

        let visible = visibleFiles(files, mode: mode)

        if self.layout == .flat {
            return visible.map { FileTreeEntry(id: $0.id, title: $0.name, depth: 0, file: $0, count: 0) }
        }

        if self.layout == .tree {
            return treeEntries(visible, prefix: "", depth: 0)
        }

        return groupedEntries(visible)

    }

    private func treeEntries(_ files: [DiffFile], prefix: String, depth: Int) -> [FileTreeEntry] {

        let directories = Set(files.compactMap { file -> String? in

            let relative = String(file.path.dropFirst(prefix.count))
            let parts = relative.split(separator: "/")
            return parts.count > 1 ? String(parts[0]) : nil

        })

        let sortedDirectories = directories.sorted { left, right in

            if self.sort == .updated {

                let leftDate = files.filter { $0.path.hasPrefix(prefix + left + "/") }.map(\.updatedMinutesAgo).min() ?? .max
                let rightDate = files.filter { $0.path.hasPrefix(prefix + right + "/") }.map(\.updatedMinutesAgo).min() ?? .max

                if leftDate != rightDate {
                    return self.ascending ? leftDate < rightDate : leftDate > rightDate
                }

            }

            return left.localizedStandardCompare(right) == .orderedAscending

        }

        var entries: [FileTreeEntry] = []

        for directory in sortedDirectories {

            let path = prefix + directory + "/"
            let descendants = files.filter { $0.path.hasPrefix(path) }
            entries.append(FileTreeEntry(id: path, title: directory, depth: depth, file: nil, count: descendants.count))

            if !self.collapsedGroups.contains(path) {
                entries.append(contentsOf: treeEntries(descendants, prefix: path, depth: depth + 1))
            }

        }

        let siblings = files.filter { !$0.path.dropFirst(prefix.count).contains("/") }
        entries.append(contentsOf: siblings.map { FileTreeEntry(id: $0.id, title: $0.name, depth: depth, file: $0, count: 0) })

        return entries

    }

    private func groupedEntries(_ files: [DiffFile]) -> [FileTreeEntry] {

        let groups = Dictionary(grouping: files) { file in
            self.layout == .status ? file.status.rawValue : file.language.capitalized
        }

        return groups.keys.sorted().flatMap { key -> [FileTreeEntry] in

            let children = groups[key] ?? []
            let heading = FileTreeEntry(id: key, title: key, depth: 0, file: nil, count: children.count)

            if self.collapsedGroups.contains(key) {
                return [heading]
            }

            return [heading] + children.map { FileTreeEntry(id: $0.id, title: $0.name, depth: 1, file: $0, count: 0) }

        }

    }

    func toggleGroup(_ id: String) {

        if self.collapsedGroups.contains(id) {
            self.collapsedGroups.remove(id)
        } else {
            self.collapsedGroups.insert(id)
        }

    }

    func clearFilters() {

        self.query = ""
        self.filter = nil

    }

}
