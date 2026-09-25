import SwiftUI
import Combine

@MainActor
final class WorkspaceViewModel: ViewModel {

    let loggerName = "WORKSPACE_VIEW_MODEL"
    @Published private(set) var projects: [RepositoryProject]
    let fileNavigatorViewModel: FileNavigatorViewModel
    private let preferencesService: PreferencesServiceProtocol
    private var localProjectRecords: [LocalProjectRecord]

    @Published var buckets: [Bucket]
    @Published var selectedProjectID: String = "rune"
    @Published var selectedFileID: String?
    @Published var mode: ComparisonMode = .workingTree
    @Published var showsDashboard = false
    @Published var showsReview = false
    @Published var showsCommandPalette = false
    @Published var showsSidebar = true
    @Published var favorites: Set<String> = ["rune", "obelisk"]
    @Published var recentProjectIDs: [String] = ["rune", "obelisk", "grimoire"]
    @Published var selectedBucket: Bucket?
    @Published var pendingProject: NewProjectDraft?
    @Published var projectBuckets: [String: String] = [:]
    @Published var annotationDraft: AnnotationDraft?
    @Published var comparisonLeft = "main"
    @Published var comparisonRight = "feature/refine-the-details"
    @Published var pendingScrollLine: Int?
    @Published var pendingMergeConflict: Int?
    @Published var notice: String?

    init(
        workspaceService: WorkspaceServiceProtocol,
        preferencesService: PreferencesServiceProtocol,
        fileNavigatorViewModel: FileNavigatorViewModel
    ) {

        let localProjects = preferencesService.load([LocalProjectRecord].self, key: "projects.local.v1") ?? []

        self.localProjectRecords = localProjects
        self.projects = workspaceService.projects + localProjects.map(\.project)
        self.preferencesService = preferencesService
        self.fileNavigatorViewModel = fileNavigatorViewModel
        self.buckets = (preferencesService.load([Bucket].self, key: "buckets.demo.v1") ?? workspaceService.buckets).map { bucket in

            var updated = bucket
            updated.enforceDesignDefaults()
            return updated

        }
        self.projectBuckets = preferencesService.load([String: String].self, key: "projectBuckets.demo.v1") ?? [:]
        self.selectedFileID = self.projects.first?.files.first?.id

    }

    var project: RepositoryProject {
        self.projects.first { $0.id == self.selectedProjectID } ?? self.projects[0]
    }

    var file: DiffFile? {
        self.project.files.first { $0.id == self.selectedFileID }
    }

    var comparisonTitle: String {

        switch self.mode {

        case .workingTree: "HEAD → Working tree"
        case .staged: "HEAD → Index"
        case .branches: "\(self.comparisonLeft) → \(self.comparisonRight)"
        case .commits: "\(self.comparisonLeft) → \(self.comparisonRight)"
        case .folders: "Original folder → Updated folder"
        case .history: "Previous version → Selected version"
        case .merge: "Base · Yours · Theirs"

        }

    }

    // MARK: - Navigation

    func selectProject(_ project: RepositoryProject) {

        self.selectedProjectID = project.id
        self.fileNavigatorViewModel.restore(projectID: project.id)
        self.selectedFileID = project.files.first?.id
        self.showsDashboard = true
        self.recentProjectIDs.removeAll { $0 == project.id }
        self.recentProjectIDs.insert(project.id, at: 0)

    }

    func selectFile(_ file: DiffFile) {

        self.selectedFileID = file.id
        self.showsDashboard = false

        self.mode = .workingTree

    }

    func selectMode(_ mode: ComparisonMode) {

        guard self.project.directoryPath == nil else {
            self.showsDashboard = true
            return
        }

        self.mode = mode
        self.showsDashboard = false

        if mode == .staged {
            self.selectedFileID = self.project.files.first(where: \.isStaged)?.id
        }

        if mode == .merge {
            self.selectedFileID = self.project.files.first(where: { $0.status == .conflicted })?.id
        }

        if mode == .commits || mode == .history {

            self.comparisonLeft = "b4f1d08"
            self.comparisonRight = "a7e2c91"

        } else {

            self.comparisonLeft = "main"
            self.comparisonRight = "feature/refine-the-details"

        }

    }

    func toggleFavorite(_ project: RepositoryProject) {

        if self.favorites.contains(project.id) {
            self.favorites.remove(project.id)
        } else {
            self.favorites.insert(project.id)
        }

    }

    // MARK: - Bucket Customization

    func bucketID(for project: RepositoryProject) -> String {
        self.projectBuckets[project.id] ?? project.bucketID
    }

    func bucket(for project: RepositoryProject) -> Bucket? {
        self.buckets.first { $0.id == bucketID(for: project) }
    }

    func prepareProject(directoryURL: URL, in bucket: Bucket) {

        let path = directoryURL.standardizedFileURL.path

        if let existing = self.projects.first(where: { $0.directoryPath == path }) {

            selectProject(existing)
            self.notice = "This folder is already in Diffy."
            return

        }

        self.pendingProject = NewProjectDraft(
            directoryPath: path,
            bucketID: bucket.id,
            name: directoryURL.lastPathComponent
        )

    }

    func addProject(_ draft: NewProjectDraft) {

        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty,
              self.buckets.contains(where: { $0.id == draft.bucketID }) else {
            return
        }

        let record = LocalProjectRecord(
            id: "local-\(UUID().uuidString)",
            directoryPath: draft.directoryPath,
            bucketID: draft.bucketID,
            name: name,
            symbol: draft.symbol
        )

        self.localProjectRecords.append(record)
        self.projects.append(record.project)
        self.preferencesService.save(self.localProjectRecords, key: "projects.local.v1")
        self.pendingProject = nil
        selectProject(record.project)
        self.notice = "Folder added to Diffy. Comparisons are not available for local folders yet."

    }

    func moveProject(_ projectID: String, to bucketID: String) {

        guard self.projects.contains(where: { $0.id == projectID }),
              self.buckets.contains(where: { $0.id == bucketID }) else {
            return
        }

        self.projectBuckets[projectID] = bucketID
        self.preferencesService.save(self.projectBuckets, key: "projectBuckets.demo.v1")

    }

    func detachProject(_ projectID: String) {

        guard self.projects.contains(where: { $0.id == projectID }) else {
            return
        }

        self.projectBuckets[projectID] = ""
        self.preferencesService.save(self.projectBuckets, key: "projectBuckets.demo.v1")

    }

    func moveBucket(_ bucket: Bucket, direction: Int) {

        guard let index = self.buckets.firstIndex(where: { $0.id == bucket.id }) else {
            return
        }

        let destination = index + direction

        guard self.buckets.indices.contains(destination) else {
            return
        }

        _ = reorderBucket(bucket.id, relativeTo: self.buckets[destination].id, placeAfter: direction > 0)

    }

    func reorderBucket(_ draggedID: String, relativeTo targetID: String, placeAfter: Bool) -> Bool {

        guard draggedID != targetID,
              let sourceIndex = self.buckets.firstIndex(where: { $0.id == draggedID }) else {
            return false
        }

        var reordered = self.buckets
        let draggedBucket = reordered.remove(at: sourceIndex)

        guard let targetIndex = reordered.firstIndex(where: { $0.id == targetID }) else {
            return false
        }

        reordered.insert(draggedBucket, at: targetIndex + (placeAfter ? 1 : 0))

        guard reordered != self.buckets else {
            return false
        }

        self.buckets = reordered
        self.preferencesService.save(self.buckets, key: "buckets.demo.v1")
        return true

    }

    func saveBucket(_ bucket: Bucket) {

        var bucket = bucket
        bucket.enforceDesignDefaults()

        if let index = self.buckets.firstIndex(where: { $0.id == bucket.id }) {
            self.buckets[index] = bucket
        } else {
            self.buckets.append(bucket)
        }

        self.preferencesService.save(self.buckets, key: "buckets.demo.v1")
        self.selectedBucket = nil

    }

    func replacementBucket(for bucket: Bucket) -> Bucket? {
        self.buckets.first { $0.id != bucket.id }
    }

    func deleteBucket(_ bucket: Bucket) {

        guard self.buckets.contains(where: { $0.id == bucket.id }),
              let replacement = replacementBucket(for: bucket) else {
            return
        }

        for project in self.projects where bucketID(for: project) == bucket.id {
            self.projectBuckets[project.id] = replacement.id
        }

        self.buckets.removeAll { $0.id == bucket.id }
        self.preferencesService.save(self.projectBuckets, key: "projectBuckets.demo.v1")
        self.preferencesService.save(self.buckets, key: "buckets.demo.v1")
        self.selectedBucket = nil

    }

    func addBucket() {

        self.selectedBucket = Bucket(
            id: UUID().uuidString,
            title: "New Bucket",
            subtitle: "A space for your projects",
            symbol: "folder",
            accentHex: "7862D9"
        )

    }

    // MARK: - Review Navigation

    func revealAnnotation(_ annotation: CodeAnnotation) {

        guard let project = self.projects.first(where: { $0.id == annotation.projectID }),
              let file = project.files.first(where: { $0.path == annotation.filePath || $0.originalPath == annotation.filePath }) else {

            self.notice = "This source is unavailable. The captured snippet is preserved in your note."
            return

        }

        self.selectedProjectID = project.id
        self.selectedFileID = file.id
        self.showsDashboard = false

        if annotation.source.hasPrefix("mock/merge/") {

            self.mode = .merge
            let component = annotation.source.components(separatedBy: "/").first { $0.hasPrefix("conflict-") }
            self.pendingMergeConflict = component.flatMap { Int($0.replacingOccurrences(of: "conflict-", with: "")) }.map { $0 - 1 }
            self.notice = annotation.side == .result ? "This note preserves an earlier result snapshot. Its original code remains in the export." : nil
            return

        }

        self.mode = ComparisonMode(rawValue: annotation.comparisonMode ?? "") ?? .workingTree

        let sources = annotation.comparison.components(separatedBy: " → ")

        if sources.count == 2 {

            self.comparisonLeft = sources[0]
            self.comparisonRight = sources[1]

        }

        let row = file.lines.first { line in
            annotation.side == .left ? line.oldNumber == annotation.startLine : line.newNumber == annotation.startLine
        }

        self.pendingScrollLine = row?.id

    }

}
