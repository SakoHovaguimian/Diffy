import SwiftUI
import Combine

@MainActor
final class WorkspaceViewModel: ViewModel {

    private static let minimumContentSizeScale = 0.5
    private static let maximumContentSizeScale = 2.0
    private static let contentSizeStep = 0.1

    let loggerName = "WORKSPACE_VIEW_MODEL"
    let runtime: AppRuntime
    let repositoryViewModel: RepositoryViewModel
    let overviewViewModel: WorkspaceOverviewViewModel
    @Published private(set) var projects: [RepositoryProject]
    let fileNavigatorViewModel: FileNavigatorViewModel
    let textDiffViewModel: TextDiffViewModel
    private let workspaceService: WorkspaceServiceProtocol
    private let preferencesService: PreferencesServiceProtocol
    private var comparisonObservation: AnyCancellable?

    @Published var buckets: [Bucket]
    @Published var selectedProjectID: String = "rune"
    @Published var selectedFileID: String?
    @Published var mode: ComparisonMode = .workingTree
    @Published var showsOverview = true
    @Published var showsDashboard = false
    @Published var showsReview = false
    @Published var showsCommandPalette = false
    @Published var showsSidebar = true
    @Published var favorites: Set<String> = ["rune", "obelisk"]
    @Published var recentProjectIDs: [String] = ["rune", "obelisk", "grimoire"]
    @Published var selectedBucket: Bucket?
    @Published var pendingProject: ProjectEditorDraft?
    @Published private(set) var projectEditorError: String?
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
        runtime: AppRuntime,
        repositoryViewModel: RepositoryViewModel,
        overviewViewModel: WorkspaceOverviewViewModel,
        workspaceService: WorkspaceServiceProtocol,
        preferencesService: PreferencesServiceProtocol,
        fileNavigatorViewModel: FileNavigatorViewModel,
        textDiffBuilder: TextDiffBuilding
    ) {

        let library = workspaceService.loadLibrary()

        self.runtime = runtime
        self.repositoryViewModel = repositoryViewModel
        self.overviewViewModel = overviewViewModel
        self.projects = library.projects
        self.workspaceService = workspaceService
        self.preferencesService = preferencesService
        self.fileNavigatorViewModel = fileNavigatorViewModel
        self.textDiffViewModel = TextDiffViewModel(diffBuilder: textDiffBuilder)
        self.buckets = (preferencesService.load([Bucket].self, key: "buckets.demo.v1") ?? workspaceService.defaultBuckets).map { bucket in

            var updated = bucket
            updated.enforceDesignDefaults()
            return updated

        }
        self.projectBuckets = preferencesService.load([String: String].self, key: "projectBuckets.demo.v1") ?? [:]
        self.projectOrder = preferencesService.load([String].self, key: "projectOrder.demo.v1") ?? []
        self.favorites = Set(library.defaultFavoriteProjectIDs)
        self.recentProjectIDs = library.defaultRecentProjectIDs
        self.notice = library.loadErrorMessage ?? library.migrationNotice
        self.selectedProjectID = self.projects.first?.id ?? ""
        self.selectedFileID = self.projects.first?.files.first?.id
        self.showsDashboard = self.projects.first?.checkout != nil

        self.fileNavigatorViewModel.restore(projectID: self.selectedProjectID)
        self.comparisonObservation = repositoryViewModel.comparison.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        migrateStarterBucketsIfNeeded()

    }

    private func migrateStarterBucketsIfNeeded() {

        let migrationKey = "buckets.personalDefault.v1"
        guard self.preferencesService.load(Bool.self, key: migrationKey) != true else { return }

        self.buckets = WorkspaceDefaults.migrateStarterBuckets(self.buckets)

        if self.buckets.isEmpty {
            self.buckets = WorkspaceDefaults.starterBuckets
        }

        if self.buckets.contains(where: { $0.id == "personal" }) {

            let bucketIDs = Set(self.buckets.map(\.id))

            for project in self.projects {

                let bucketID = bucketID(for: project)

                if WorkspaceDefaults.retiredBucketIDs.contains(bucketID), !bucketIDs.contains(bucketID) {
                    self.projectBuckets[project.id] = "personal"
                }

            }

        }

        self.preferencesService.save(self.projectBuckets, key: "projectBuckets.demo.v1")
        self.preferencesService.save(self.buckets, key: "buckets.demo.v1")
        self.preferencesService.save(true, key: migrationKey)

    }

    var selectedProject: RepositoryProject? {
        self.projects.first { $0.id == self.selectedProjectID } ?? self.projects.first
    }

    var project: RepositoryProject {

        guard let selectedProject = self.selectedProject else {
            preconditionFailure("A project-dependent screen was shown without a selected project.")
        }

        return selectedProject

    }

    var files: [DiffFile] {
        self.runtime.isLive ? self.repositoryViewModel.comparison.files : self.selectedProject?.files ?? []
    }

    var currentFileID: String? {
        self.runtime.isLive ? self.repositoryViewModel.comparison.selectedFileID : self.selectedFileID
    }

    var file: DiffFile? {
        self.runtime.isLive ? self.repositoryViewModel.comparison.selectedFile : self.files.first { $0.id == self.selectedFileID }
    }

    var comparisonTitle: String {

        if self.runtime.isLive {
            return self.repositoryViewModel.comparison.selection.title
        }

        return switch self.mode {

        case .workingTree: "HEAD → Working tree"
        case .staged: "HEAD → Index"
        case .branches: "\(self.comparisonLeft) → \(self.comparisonRight)"
        case .commits: "\(self.comparisonLeft) → \(self.comparisonRight)"
        case .history: "Previous version → Selected version"
        case .pullRequests: "Pull request base → Head"
        case .merge: "Base · Yours · Theirs"
        case .folders: "Original folder → Updated folder"

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

        guard !self.repositoryViewModel.isOperating else { return }
        requestNavigation(.project(projectID: project.id, opensWorkingTree: false))
    }

    func openWorkingTree(for project: RepositoryProject) {

        guard !self.repositoryViewModel.isOperating else { return }
        requestNavigation(.project(projectID: project.id, opensWorkingTree: true))
    }

    func selectFile(_ file: DiffFile, mode: ComparisonMode = .workingTree) {
        requestNavigation(.file(projectID: self.project.id, fileID: file.id, mode: mode))
    }

    func selectMode(_ mode: ComparisonMode) {

        guard self.selectedProject != nil else {
            return
        }

        requestNavigation(.mode(mode))

    }

    func showDashboard() {
        requestNavigation(.dashboard)
    }

    func showOverview() {
        requestNavigation(.overview)
    }

    func showFileHistory(_ file: DiffFile) {

        if self.runtime.isLive {

            self.repositoryViewModel.showsPatch = false
            selectMode(.history)
            Task { await self.repositoryViewModel.loadHistory(path: file.path) }

        } else {
            selectFile(file, mode: .history)
        }

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

        if self.repositoryViewModel.isOperating { return }

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

        case .overview:
            return self.showsOverview

        case .dashboard:
            return !self.showsOverview && self.showsDashboard

        case let .file(projectID, fileID, mode):
            return !self.showsOverview && !self.showsDashboard && self.selectedProjectID == projectID && self.currentFileID == fileID && self.mode == mode

        case let .mode(mode):
            return !self.showsOverview && !self.showsDashboard && self.mode == mode

        case let .project(projectID, opensWorkingTree):
            return !self.showsOverview && self.selectedProjectID == projectID && (opensWorkingTree ? !self.showsDashboard && self.mode == .workingTree : self.showsDashboard)

        case .annotation:
            return false

        }

    }

    private func performNavigation(_ destination: DiffNavigationDestination) {

        switch destination {

        case .overview:
            self.showsOverview = true

        case .dashboard:
            self.showsOverview = false
            self.showsDashboard = true
            self.mode = .workingTree

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
        self.showsOverview = false
        self.fileNavigatorViewModel.restore(projectID: project.id)
        self.selectedFileID = project.files.first?.id
        self.mode = .workingTree
        self.showsDashboard = !opensWorkingTree
        self.recentProjectIDs.removeAll { $0 == project.id }
        self.recentProjectIDs.insert(project.id, at: 0)

    }

    private func navigateToFile(projectID: String, fileID: String, mode: ComparisonMode) {

        if self.runtime.isLive, projectID == self.selectedProjectID,
           let file = self.files.first(where: { $0.id == fileID }) {

            self.repositoryViewModel.comparison.select(file)

            if !self.repositoryViewModel.showsPatch {

                self.showsOverview = false
                self.showsDashboard = false
                self.mode = mode

            }

            return

        }

        guard let project = self.projects.first(where: { $0.id == projectID }),
              project.files.contains(where: { $0.id == fileID }) else {
            return
        }

        self.selectedProjectID = projectID
        self.showsOverview = false
        self.selectedFileID = fileID
        self.showsDashboard = false
        self.mode = mode

    }

    private func navigateToMode(_ mode: ComparisonMode) {

        self.mode = mode
        self.showsOverview = false
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

    // MARK: - Live Project Library

    func reloadProjects() {

        let library = self.workspaceService.loadLibrary()
        self.projects = library.projects

        if !self.projects.contains(where: { $0.id == self.selectedProjectID }) {

            self.selectedProjectID = self.projects.last?.id ?? ""
            self.showsOverview = self.showsOverview || self.projects.isEmpty
            self.showsDashboard = !self.showsOverview

        }

        if let error = library.loadErrorMessage { self.notice = error }

        if let selectedProject, self.repositoryViewModel.project?.id == selectedProject.id {
            Task { await self.repositoryViewModel.load(selectedProject) }
        }

    }

    func relocateSelectedProject(to directory: URL) {

        guard var project = self.selectedProject else { return }

        do {

            project.checkout = try self.workspaceService.makeCheckoutReference(for: directory)
            let updated = self.workspaceService.loadLibrary().projects.map { $0.id == project.id ? project : $0 }
            try self.workspaceService.saveProjects(updated)
            self.projects = updated
            Task { await self.repositoryViewModel.load(project) }

        } catch {
            self.notice = error.localizedDescription
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

        self.projectEditorError = nil
        self.pendingProject = ProjectEditorDraft(
            directoryURL: directoryURL.standardizedFileURL,
            bucketID: bucket?.id ?? ""
        )

    }

    func editProject(_ project: RepositoryProject) {

        self.projectEditorError = nil
        self.pendingProject = ProjectEditorDraft(project: project, bucketID: bucketID(for: project))

    }

    func saveProject(_ draft: ProjectEditorDraft) {

        self.projectEditorError = nil

        guard !draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {

            self.projectEditorError = "Enter a display name for this project."
            return

        }

        if let projectID = draft.projectID {
            updateProject(projectID, from: draft)
        } else {
            addProject(draft)
        }

    }

    private func updateProject(_ projectID: String, from draft: ProjectEditorDraft) {

        var updatedProjects = self.workspaceService.loadLibrary().projects

        guard let index = updatedProjects.firstIndex(where: { $0.id == projectID }) else {

            self.projectEditorError = "This project is no longer in your library."
            return

        }

        updatedProjects[index].displayName = draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedProjects[index].symbol = draft.symbol

        do {

            try self.workspaceService.saveProjects(updatedProjects)
            self.projects = updatedProjects
            self.repositoryViewModel.updateProjectPresentation(updatedProjects[index])
            self.pendingProject = nil
            self.notice = "Project updated."

        } catch {
            self.projectEditorError = "Diffy could not save this project: \(error.localizedDescription)"
        }

    }

    private func addProject(_ draft: ProjectEditorDraft) {

        let hasValidDestination = draft.bucketID.isEmpty || self.buckets.contains { $0.id == draft.bucketID }

        guard let directoryURL = draft.directoryURL, hasValidDestination else {

            self.projectEditorError = "Choose a project folder and an available Bucket."
            return

        }

        do {

            let checkout = try self.workspaceService.makeCheckoutReference(for: directoryURL)
            let project = RepositoryProject(
                id: "local-\(UUID().uuidString)",
                name: directoryURL.lastPathComponent,
                displayName: draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                subtitle: "",
                bucketID: draft.bucketID,
                symbol: draft.symbol,
                checkout: checkout,
                gitHubLink: nil,
                gitHubAccountID: nil,
                addedAt: Date()
            )
            let updatedProjects = self.workspaceService.loadLibrary().projects + [project]

            try self.workspaceService.saveProjects(updatedProjects)
            self.projects = updatedProjects
            self.pendingProject = nil
            selectProject(project)
            self.notice = "Project added to Diffy."

        } catch {
            self.projectEditorError = "Diffy could not save this folder: \(error.localizedDescription)"
        }

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
              !self.runtime.isLive || (project.id == self.selectedProjectID && annotation.comparison == self.comparisonTitle),
              let file = (self.runtime.isLive ? self.files : project.files).first(where: { $0.path == annotation.filePath || $0.originalPath == annotation.filePath }) else {

            self.notice = "This source is unavailable. The captured snippet is preserved in your note."
            return

        }

        self.selectedProjectID = project.id
        self.showsOverview = false
        self.selectedFileID = file.id
        self.showsDashboard = false

        if self.runtime.isLive {

            self.repositoryViewModel.comparison.select(file)
            self.repositoryViewModel.comparison.reveal(lineNumber: annotation.startLine, side: annotation.side)
            return

        }

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
