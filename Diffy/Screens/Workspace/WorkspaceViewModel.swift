import SwiftUI
import Combine

@MainActor
final class WorkspaceViewModel: ViewModel {

    private static let minimumContentSizeScale = 0.5
    private static let maximumContentSizeScale = 2.0
    private static let contentSizeStep = 0.1

    let loggerName = "WORKSPACE_VIEW_MODEL"
    @Published private(set) var projects: [RepositoryProject]
    let fileNavigatorViewModel: FileNavigatorViewModel
    let textDiffViewModel: TextDiffViewModel
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
    @Published private(set) var projectOrder: [String] = []
    @Published var projectDropTargetID: String?
    @Published var projectBuckets: [String: String] = [:]
    @Published var annotationDraft: AnnotationDraft?
    @Published var comparisonLeft = "main"
    @Published var comparisonRight = "feature/refine-the-details"
    @Published var pendingScrollLine: Int?
    @Published var pendingMergeConflict: Int?
    @Published var pendingDiffNavigation: PendingDiffNavigation?
    @Published var notice: String?
    @Published private(set) var contentSizeScale = 1.0

    init(
        workspaceService: WorkspaceServiceProtocol,
        preferencesService: PreferencesServiceProtocol,
        fileNavigatorViewModel: FileNavigatorViewModel,
        textDiffBuilder: TextDiffBuilding
    ) {

        let localProjects = preferencesService.load([LocalProjectRecord].self, key: "projects.local.v1") ?? []

        self.localProjectRecords = localProjects
        self.projects = workspaceService.projects + localProjects.map(\.project)
        self.preferencesService = preferencesService
        self.fileNavigatorViewModel = fileNavigatorViewModel
        self.textDiffViewModel = TextDiffViewModel(diffBuilder: textDiffBuilder)
        self.buckets = (preferencesService.load([Bucket].self, key: "buckets.demo.v1") ?? workspaceService.buckets).map { bucket in

            var updated = bucket
            updated.enforceDesignDefaults()
            return updated

        }
        self.projectBuckets = preferencesService.load([String: String].self, key: "projectBuckets.demo.v1") ?? [:]
        self.projectOrder = preferencesService.load([String].self, key: "projectOrder.demo.v1") ?? []
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

    // MARK: - Content Size

    func increaseContentSize() {
        setContentSizeScale(self.contentSizeScale + Self.contentSizeStep)
    }

    func decreaseContentSize() {
        setContentSizeScale(self.contentSizeScale - Self.contentSizeStep)
    }

    func resetContentSize() {
        setContentSizeScale(1)
    }

    private func setContentSizeScale(_ scale: Double) {

        let clampedScale = min(Self.maximumContentSizeScale, max(Self.minimumContentSizeScale, scale))
        self.contentSizeScale = (clampedScale * 10).rounded() / 10

    }

    // MARK: - Navigation

    func selectProject(_ project: RepositoryProject) {
        requestNavigation(.project(projectID: project.id, opensWorkingTree: false))
    }

    func openWorkingTree(for project: RepositoryProject) {
        requestNavigation(.project(projectID: project.id, opensWorkingTree: true))
    }

    func selectFile(_ file: DiffFile, mode: ComparisonMode = .workingTree) {
        requestNavigation(.file(projectID: self.project.id, fileID: file.id, mode: mode))
    }

    func selectMode(_ mode: ComparisonMode) {
        requestNavigation(.mode(mode))
    }

    func showDashboard() {
        requestNavigation(.dashboard)
    }

    func resolvePendingDiffNavigation(_ decision: DiffNavigationDecision) {

        guard let pendingDiffNavigation = self.pendingDiffNavigation else {
            return
        }

        switch decision {

        case .apply:
            self.textDiffViewModel.applyChanges()

        case .discard:
            self.textDiffViewModel.discardChanges()

        case .cancel:
            self.pendingDiffNavigation = nil
            return

        }

        self.pendingDiffNavigation = nil
        performNavigation(pendingDiffNavigation.destination)

    }

    private func requestNavigation(_ destination: DiffNavigationDestination) {

        guard !isCurrentDestination(destination) else {
            return
        }

        guard self.textDiffViewModel.hasUnappliedChanges else {

            performNavigation(destination)
            return

        }

        self.pendingDiffNavigation = PendingDiffNavigation(destination: destination)

    }

    private func isCurrentDestination(_ destination: DiffNavigationDestination) -> Bool {

        switch destination {

        case .dashboard:
            return self.showsDashboard

        case let .file(projectID, fileID, mode):
            return !self.showsDashboard && self.selectedProjectID == projectID && self.selectedFileID == fileID && self.mode == mode

        case let .mode(mode):
            return !self.showsDashboard && self.mode == mode

        case let .project(projectID, opensWorkingTree):
            return self.selectedProjectID == projectID && (opensWorkingTree ? !self.showsDashboard && self.mode == .workingTree : self.showsDashboard)

        case .annotation:
            return false

        }

    }

    private func performNavigation(_ destination: DiffNavigationDestination) {

        switch destination {

        case .dashboard:
            self.showsDashboard = true

        case let .file(projectID, fileID, mode):
            navigateToFile(projectID: projectID, fileID: fileID, mode: mode)

        case let .mode(mode):
            navigateToMode(mode)

        case let .project(projectID, opensWorkingTree):
            navigateToProject(projectID: projectID, opensWorkingTree: opensWorkingTree)

        case let .annotation(annotation):
            reveal(annotation)

        }

    }

    private func navigateToProject(projectID: String, opensWorkingTree: Bool) {

        guard let project = self.projects.first(where: { $0.id == projectID }) else {
            return
        }

        self.selectedProjectID = project.id
        self.fileNavigatorViewModel.restore(projectID: project.id)
        self.selectedFileID = project.files.first?.id
        self.mode = .workingTree
        self.showsDashboard = !opensWorkingTree
        self.recentProjectIDs.removeAll { $0 == project.id }
        self.recentProjectIDs.insert(project.id, at: 0)

    }

    private func navigateToFile(projectID: String, fileID: String, mode: ComparisonMode) {

        guard let project = self.projects.first(where: { $0.id == projectID }),
              project.files.contains(where: { $0.id == fileID }) else {
            return
        }

        self.selectedProjectID = projectID
        self.selectedFileID = fileID
        self.showsDashboard = false
        self.mode = mode

    }

    private func navigateToMode(_ mode: ComparisonMode) {

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

    func prepareProject(directoryURL: URL, in bucket: Bucket?) {

        let path = directoryURL.standardizedFileURL.path

        if let existing = self.projects.first(where: { $0.directoryPath == path }) {

            selectProject(existing)
            self.notice = "This folder is already in Diffy."
            return

        }

        self.pendingProject = NewProjectDraft(
            directoryPath: path,
            bucketID: bucket?.id ?? "",
            name: directoryURL.lastPathComponent
        )

    }

    func addProject(_ draft: NewProjectDraft) {

        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        let hasValidDestination = draft.bucketID.isEmpty || self.buckets.contains { $0.id == draft.bucketID }

        guard !name.isEmpty, hasValidDestination else {
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

    func orderedProjects(in bucketID: String?) -> [RepositoryProject] {

        let matchingProjects = self.projects.filter { project in
            self.bucket(for: project)?.id == bucketID
        }
        let ordered = self.projectOrder.compactMap { id in matchingProjects.first { $0.id == id } }
        let remaining = matchingProjects.filter { !self.projectOrder.contains($0.id) }

        return ordered + remaining

    }

    func reorderProject(_ draggedID: String, relativeTo targetID: String, placeAfter: Bool) -> Bool {

        guard let target = self.projects.first(where: { $0.id == targetID }),
              self.projects.contains(where: { $0.id == draggedID }) else {
            return false
        }

        guard draggedID != targetID else {
            return true
        }

        let destinationBucketID = self.bucket(for: target)?.id ?? ""
        var reordered = orderedProjectIDs().filter { $0 != draggedID }

        guard let targetIndex = reordered.firstIndex(of: targetID) else {
            return false
        }

        reordered.insert(draggedID, at: targetIndex + (placeAfter ? 1 : 0))
        self.projectBuckets[draggedID] = destinationBucketID
        self.projectOrder = reordered
        saveProjectArrangement()
        return true

    }

    func moveProject(_ projectID: String, to bucketID: String) {

        guard self.buckets.contains(where: { $0.id == bucketID }) else {
            return
        }

        appendProject(projectID, to: bucketID)

    }

    func detachProject(_ projectID: String) {
        appendProject(projectID, to: "")
    }

    private func appendProject(_ projectID: String, to bucketID: String) {

        guard self.projects.contains(where: { $0.id == projectID }) else {
            return
        }

        self.projectOrder = orderedProjectIDs().filter { $0 != projectID } + [projectID]
        self.projectBuckets[projectID] = bucketID
        saveProjectArrangement()

    }

    private func orderedProjectIDs() -> [String] {

        let currentIDs = self.projects.map(\.id)
        let savedIDs = self.projectOrder.filter { currentIDs.contains($0) }

        return savedIDs + currentIDs.filter { !savedIDs.contains($0) }

    }

    private func saveProjectArrangement() {

        self.preferencesService.save(self.projectBuckets, key: "projectBuckets.demo.v1")
        self.preferencesService.save(self.projectOrder, key: "projectOrder.demo.v1")

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
        requestNavigation(.annotation(annotation))
    }

    private func reveal(_ annotation: CodeAnnotation) {

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
