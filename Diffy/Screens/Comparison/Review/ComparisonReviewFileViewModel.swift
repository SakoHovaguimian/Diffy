import Foundation
import Combine

@MainActor
final class ComparisonReviewFileViewModel: ViewModel, Identifiable {

    let loggerName = "COMPARISON_REVIEW_FILE_VIEW_MODEL"
    let id: String
    let textDiff: TextDiffViewModel
    private let repository: GitRepositoryReference
    private let selection: ComparisonSelection
    private let git: GitServiceProtocol

    @Published private(set) var file: DiffFile
    @Published var isExpanded: Bool
    @Published private(set) var isViewed = false
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var images: ImageComparisonSources?
    private var hasLoaded = false
    private var requestID = UUID()

    init(
        file: DiffFile,
        request: ComparisonReviewRequest,
        selection: ComparisonSelection,
        git: GitServiceProtocol,
        diffBuilder: TextDiffBuilding
    ) {

        self.id = file.id
        self.file = file
        self.repository = request.repository
        self.selection = selection
        self.isExpanded = request.startsExpanded
        self.git = git
        self.textDiff = TextDiffViewModel(diffBuilder: diffBuilder)

    }

    var counts: DiffLineCounts {
        self.file.lineCounts ?? DiffLineCounts(additions: self.file.additions + self.file.changedLines, deletions: self.file.deletions + self.file.changedLines)
    }

    func markViewed(_ viewed: Bool) {

        self.isViewed = viewed
        self.isExpanded = !viewed

    }

    func load() async {

        guard !self.hasLoaded else { return }
        let requestID = UUID()
        self.requestID = requestID
        self.isLoading = true
        self.error = nil
        defer { if self.requestID == requestID { self.isLoading = false } }

        do {

            let file = try await self.git.fileComparison(in: self.repository, selection: self.selection, file: self.file)
            let images = file.kind == .image ? try await self.git.imageSources(in: self.repository, selection: self.selection, file: file) : nil
            try Task.checkCancellation()
            guard self.requestID == requestID else { return }
            self.file = file
            self.images = images
            self.hasLoaded = true

        } catch is CancellationError {
            return
        } catch {

            guard !Task.isCancelled, self.requestID == requestID else { return }
            self.error = error.localizedDescription

        }

    }

}
