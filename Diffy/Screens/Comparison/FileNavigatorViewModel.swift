import SwiftUI
import Combine

@MainActor
final class FileNavigatorViewModel: ViewModel {

    let loggerName = "FILE_NAVIGATOR_VIEW_MODEL"
    private let preferencesService: PreferencesServiceProtocol
    private var projectID = "rune"
    private var initialLayout: FileListLayout = .tree
    private var unavailableSortOrders: Set<FileSortOrder> = []
    private var isRestoring = false
    private var cachedInput: FileNavigatorInput?
    private var cachedVisibleFiles: [DiffFile] = []
    private var cachedEntries: [FileTreeEntry] = []
    private var cachedLayout: FileListLayout?
    private var cachedCollapsedGroups: Set<String> = []

    @Published var query = ""
    @Published var sort: FileSortOrder = .path
    @Published var layout: FileListLayout = .tree

    @Published var ascending = true {
        didSet { persistSelection(self.ascending, key: "navigation.ascending") }
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

    func restore(
        projectID: String,
        initialLayout: FileListLayout = .tree,
        unavailableSortOrders: Set<FileSortOrder> = []
    ) {

        self.isRestoring = true
        self.projectID = projectID
        self.initialLayout = initialLayout
        self.unavailableSortOrders = unavailableSortOrders

        let preferences = self.preferencesService.load(FileNavigationPreferences.self, key: "navigation.\(projectID)") ?? FileNavigationPreferences()

        applyNavigationDefaults()
        self.ascending = self.preferencesService.load(Bool.self, key: "navigation.ascending") ?? preferences.ascending
        self.filter = preferences.filter
        self.query = ""
        self.collapsedGroups = []
        self.isRestoring = false

    }

    func restoreNavigationDefaults() {

        self.isRestoring = true
        applyNavigationDefaults()
        self.ascending = self.preferencesService.load(Bool.self, key: "navigation.ascending") ?? self.ascending
        self.isRestoring = false

    }

    private func applyNavigationDefaults() {

        let defaults = self.preferencesService.load(FileNavigationDefaults.self, key: FileNavigationDefaults.storageKey) ?? FileNavigationDefaults()
        self.layout = defaults.layout ?? self.initialLayout
        self.sort = self.unavailableSortOrders.contains(defaults.sort) ? .path : defaults.sort

    }

    private func persistSelection<Value: Encodable>(_ value: Value, key: String) {

        guard !self.isRestoring else { return }
        self.preferencesService.save(value, key: key)
        persist()

    }

    private func persist() {

        guard !self.isRestoring else {
            return
        }

        let preferences = FileNavigationPreferences(ascending: self.ascending, filter: self.filter)
        self.preferencesService.save(preferences, key: "navigation.\(self.projectID)")

    }

    // MARK: - Visible Files

    func visibleFiles(_ files: [DiffFile], mode: ComparisonMode) -> [DiffFile] {

        let input = FileNavigatorInput(
            files: files,
            mode: mode,
            query: self.query,
            sort: self.sort,
            ascending: self.ascending,
            filter: self.filter,
            dateMinute: self.sort == .updated ? Int(Date().timeIntervalSince1970 / 60) : nil
        )
        guard self.cachedInput != input else { return self.cachedVisibleFiles }

        self.cachedVisibleFiles = sortFiles(filterFiles(files, mode: mode))
        self.cachedInput = input
        self.cachedLayout = nil
        self.cachedEntries = []
        return self.cachedVisibleFiles

    }

    private func filterFiles(_ files: [DiffFile], mode: ComparisonMode) -> [DiffFile] {

        files.filter { file in

            let matchesQuery = self.query.isEmpty || file.path.localizedCaseInsensitiveContains(self.query)
                || (file.originalPath?.localizedCaseInsensitiveContains(self.query) ?? false)
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

        guard self.cachedLayout != self.layout || self.cachedCollapsedGroups != self.collapsedGroups else {
            return self.cachedEntries
        }

        self.cachedEntries = makeEntries(visible)
        self.cachedLayout = self.layout
        self.cachedCollapsedGroups = self.collapsedGroups
        return self.cachedEntries

    }

    private func makeEntries(_ visible: [DiffFile]) -> [FileTreeEntry] {

        if self.layout == .flat {
            return visible.map { FileTreeEntry(id: $0.id, title: $0.name, depth: 0, file: $0, count: 0) }
        }

        if self.layout == .tree {
            return treeEntries(visible, prefix: "", depth: 0)
        }

        return groupedEntries(visible)

    }

    private func treeEntries(_ files: [DiffFile], prefix: String, depth: Int) -> [FileTreeEntry] {

        let descendantsByDirectory = Dictionary(grouping: files.filter { $0.path.dropFirst(prefix.count).contains("/") }) { file in
            String(file.path.dropFirst(prefix.count).split(separator: "/")[0])
        }
        let earliestUpdates = self.sort == .updated ? descendantsByDirectory.mapValues { $0.map(\.updatedMinutesAgo).min() ?? .max } : [:]

        let sortedDirectories = descendantsByDirectory.keys.sorted { left, right in

            if self.sort == .updated {

                let leftDate = earliestUpdates[left] ?? .max
                let rightDate = earliestUpdates[right] ?? .max

                if leftDate != rightDate {
                    return self.ascending ? leftDate < rightDate : leftDate > rightDate
                }

            }

            return left.localizedStandardCompare(right) == .orderedAscending

        }

        var entries: [FileTreeEntry] = []

        for directory in sortedDirectories {

            let path = prefix + directory + "/"
            let descendants = descendantsByDirectory[directory] ?? []
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

    func collapseAllGroups(in files: [DiffFile], mode: ComparisonMode) {

        let previousGroups = self.collapsedGroups
        self.collapsedGroups = []
        let groups = entries(files, mode: mode).filter { $0.file == nil }.map(\.id)
        self.collapsedGroups = previousGroups.union(groups)

    }

    func clearFilters() {

        self.query = ""
        self.filter = nil

    }

}
