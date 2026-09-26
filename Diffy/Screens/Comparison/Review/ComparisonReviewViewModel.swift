import Foundation
import Combine

@MainActor
final class ComparisonReviewViewModel: ViewModel {

    let loggerName = "COMPARISON_REVIEW_VIEW_MODEL"
    let request: ComparisonReviewRequest
    let navigator: FileNavigatorViewModel
    private let git: GitServiceProtocol
    private let diffBuilder: TextDiffBuilding
    private var fileObservations: [AnyCancellable] = []
    private var navigatorObservation: AnyCancellable?
    private var filterObservation: AnyCancellable?
    private var hasLoaded = false
    private var navigatorDragStartWidth: CGFloat?

    @Published private(set) var files: [ComparisonReviewFileViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var experience: ComparisonReviewExperience = .review
    @Published var selectedFileID: String?
    @Published var navigatorWidth: CGFloat = 245
    @Published var onlyUnviewed = false { didSet { self.visibleLimit = 50 } }
    @Published var visibleLimit = 50
    @Published var annotationDraft: AnnotationDraft?

    init(
        request: ComparisonReviewRequest,
        git: GitServiceProtocol,
        diffBuilder: TextDiffBuilding,
        navigator: FileNavigatorViewModel
    ) {

        self.request = request
        self.git = git
        self.diffBuilder = diffBuilder
        self.navigator = navigator
        navigator.restore(projectID: request.repository.projectID, initialLayout: .flat)
        self.navigatorObservation = navigator.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        self.filterObservation = navigator.$query.combineLatest(navigator.$filter, navigator.$sort, navigator.$ascending)
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.resetVisibleLimit() }

    }

    var matchingFiles: [ComparisonReviewFileViewModel] {

        let matchingIDs = self.navigator.visibleFiles(self.navigationFiles, mode: self.request.mode).map(\.id)
        let filesByID = Dictionary(uniqueKeysWithValues: self.files.map { ($0.id, $0) })
        return matchingIDs.compactMap { filesByID[$0] }

    }

    var navigationFiles: [DiffFile] {
        self.files.filter { !self.onlyUnviewed || !$0.isViewed }.map(\.file)
    }

    var reviewEntries: [FileTreeEntry] {
        self.navigator.entries(self.visibleFiles.map(\.file), mode: self.request.mode)
    }

    var selectedFile: ComparisonReviewFileViewModel? {
        self.matchingFiles.first { $0.id == self.selectedFileID }
    }

    func fileViewModel(for id: String) -> ComparisonReviewFileViewModel? {
        self.files.first { $0.id == id }
    }

    var visibleFiles: [ComparisonReviewFileViewModel] {
        Array(self.matchingFiles.prefix(self.visibleLimit))
    }

    var viewedCount: Int {
        self.files.filter(\.isViewed).count
    }

    var counts: DiffLineCounts {
        DiffLineCounts(additions: self.files.reduce(0) { $0 + $1.counts.additions }, deletions: self.files.reduce(0) { $0 + $1.counts.deletions })
    }

    var hasUnavailableLineCounts: Bool {
        self.files.contains { $0.file.lineCounts == nil }
    }

    func expandShown() {
        self.reviewEntries.compactMap(\.file).forEach { self.fileViewModel(for: $0.id)?.isExpanded = true }
    }

    func collapseAll() {
        self.files.forEach { $0.isExpanded = false }
    }

    func clearFilters() {

        self.navigator.clearFilters()
        self.onlyUnviewed = false

    }

    private func resetVisibleLimit() {

        guard self.visibleLimit != 50 else { return }
        self.visibleLimit = 50

    }

    func load() async {

        guard !self.hasLoaded, !self.isLoading, let selection = self.request.selection else { return }
        self.isLoading = true
        self.error = nil
        defer { self.isLoading = false }

        do {

            let files = try await self.git.comparisonFiles(in: self.request.repository, selection: selection)
            try Task.checkCancellation()
            self.files = files.map {
                ComparisonReviewFileViewModel(file: $0, request: self.request, selection: selection, git: self.git, diffBuilder: self.diffBuilder)
            }
            self.fileObservations = self.files.map { file in

                file.$isViewed.dropFirst()
                    .map { _ in () }
                    .merge(with: file.$file.dropFirst().map { _ in () })
                    .receive(on: RunLoop.main)
                    .sink { [weak self] _ in self?.objectWillChange.send() }

            }
            self.selectedFileID = self.matchingFiles.first?.id
            self.hasLoaded = true

        } catch is CancellationError {
            return
        } catch {

            guard !Task.isCancelled else { return }
            self.error = error.localizedDescription

        }

    }

    func selectFile(_ file: DiffFile) {
        self.selectedFileID = file.id
    }

    func resizeNavigator(by translation: CGFloat, maximumWidth: CGFloat) {

        if self.navigatorDragStartWidth == nil {
            self.navigatorDragStartWidth = min(self.navigatorWidth, maximumWidth)
        }

        let startingWidth = self.navigatorDragStartWidth ?? self.navigatorWidth
        self.navigatorWidth = min(maximumWidth, max(205, startingWidth + translation))

    }

    func finishResizingNavigator() {
        self.navigatorDragStartWidth = nil
    }

}
