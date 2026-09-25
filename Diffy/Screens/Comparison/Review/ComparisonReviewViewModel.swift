import Foundation
import Combine

@MainActor
final class ComparisonReviewViewModel: ViewModel {

    let loggerName = "COMPARISON_REVIEW_VIEW_MODEL"
    let request: ComparisonReviewRequest
    private let git: GitServiceProtocol
    private let diffBuilder: TextDiffBuilding
    private var fileObservations: [AnyCancellable] = []
    private var hasLoaded = false

    @Published private(set) var files: [ComparisonReviewFileViewModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var query = "" { didSet { self.visibleLimit = 50 } }
    @Published var onlyUnviewed = false { didSet { self.visibleLimit = 50 } }
    @Published var visibleLimit = 50
    @Published var annotationDraft: AnnotationDraft?

    init(
        request: ComparisonReviewRequest,
        git: GitServiceProtocol,
        diffBuilder: TextDiffBuilding
    ) {

        self.request = request
        self.git = git
        self.diffBuilder = diffBuilder

    }

    var matchingFiles: [ComparisonReviewFileViewModel] {

        self.files.filter {
            (!self.onlyUnviewed || !$0.isViewed) && (self.query.isEmpty || $0.file.path.localizedStandardContains(self.query) || ($0.file.originalPath?.localizedStandardContains(self.query) ?? false))
        }

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

    func expandShown() {
        self.visibleFiles.forEach { $0.isExpanded = true }
    }

    func collapseAll() {
        self.files.forEach { $0.isExpanded = false }
    }

    func clearFilters() {

        self.query = ""
        self.onlyUnviewed = false

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

                file.objectWillChange.sink { [weak self] _ in
                    self?.objectWillChange.send()
                }

            }
            self.hasLoaded = true

        } catch is CancellationError {
            return
        } catch {

            guard !Task.isCancelled else { return }
            self.error = error.localizedDescription

        }

    }

}
