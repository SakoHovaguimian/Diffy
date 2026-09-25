import Foundation
import Combine

/// Live comparison state is separate from the project's immutable preview fixtures.
@MainActor
final class RepositoryComparisonViewModel: ViewModel {

    let loggerName = "REPOSITORY_COMPARISON_VIEW_MODEL"
    private let git: GitServiceProtocol
    private var repository: GitRepositoryReference?
    private var listingTask: Task<Void, Never>?
    private var fileTask: Task<Void, Never>?
    private var requestID = UUID()
    private var fileRequestID = UUID()
    private var pendingLine: (number: Int, side: SourceSide)?

    @Published private(set) var scrollTarget: Int?
    @Published private(set) var selection = ComparisonSelection.workingTree
    @Published private(set) var files: [DiffFile] = []
    @Published private(set) var selectedFileID: String?
    @Published private(set) var selectedFile: DiffFile?
    @Published private(set) var imageSources: ImageComparisonSources?
    @Published private(set) var isLoadingFiles = false
    @Published private(set) var isLoadingFile = false
    @Published private(set) var listingError: String?
    @Published private(set) var fileError: String?

    init(git: GitServiceProtocol) {
        self.git = git
    }

    func reset() {

        self.listingTask?.cancel()
        self.fileTask?.cancel()
        self.requestID = UUID()
        self.fileRequestID = UUID()
        self.pendingLine = nil
        self.scrollTarget = nil
        self.repository = nil
        self.files = []
        self.selectedFileID = nil
        self.selectedFile = nil
        self.imageSources = nil
        self.listingError = nil
        self.fileError = nil
        self.isLoadingFiles = false
        self.isLoadingFile = false

    }

    func load(in repository: GitRepositoryReference, selection: ComparisonSelection) {

        let retainsSelection = self.repository == repository && self.selection == selection
        let previousFile = retainsSelection ? self.selectedFile : nil
        let previousPath = previousFile?.path
        let previousFiles = retainsSelection ? self.files : []
        reset()
        self.repository = repository
        self.selection = selection
        self.files = previousFiles
        self.selectedFile = previousFile
        self.selectedFileID = previousFile?.id
        self.isLoadingFiles = true
        let requestID = self.requestID
        self.listingTask = Task {

            do {

                let files = try await self.git.comparisonFiles(in: repository, selection: selection)
                try Task.checkCancellation()
                guard self.requestID == requestID else { return }
                self.files = files
                self.isLoadingFiles = false

                if let file = files.first(where: { $0.path == previousPath }) ?? files.first {
                    select(file)
                } else {

                    self.selectedFileID = nil
                    self.selectedFile = nil
                    self.imageSources = nil

                }

            } catch {

                guard self.requestID == requestID, !Task.isCancelled else { return }
                self.isLoadingFiles = false
                self.listingError = error.localizedDescription

            }

        }

    }

    func select(_ file: DiffFile) {

        guard let repository else { return }
        self.fileTask?.cancel()
        let requestID = UUID()
        self.fileRequestID = requestID
        self.pendingLine = nil
        self.scrollTarget = nil
        self.selectedFileID = file.id
        self.selectedFile = file
        self.imageSources = nil
        self.fileError = nil
        self.isLoadingFile = true
        let selection = self.selection
        self.fileTask = Task {

            do {

                let loaded = try await self.git.fileComparison(in: repository, selection: selection, file: file)
                let images = loaded.kind == .image ? try await self.git.imageSources(in: repository, selection: selection, file: loaded) : nil
                try Task.checkCancellation()
                guard self.fileRequestID == requestID else { return }
                self.selectedFile = loaded
                self.imageSources = images
                self.isLoadingFile = false
                resolvePendingLine()

                if let index = self.files.firstIndex(where: { $0.id == loaded.id }) {
                    self.files[index] = loaded
                }

            } catch {

                guard self.fileRequestID == requestID, !Task.isCancelled else { return }
                self.isLoadingFile = false
                self.fileError = error.localizedDescription

            }

        }

    }

    func reveal(lineNumber: Int, side: SourceSide) {

        self.pendingLine = (lineNumber, side)

        if !self.isLoadingFile {
            resolvePendingLine()
        }

    }

    private func resolvePendingLine() {

        guard let pendingLine, let file = self.selectedFile else { return }
        self.scrollTarget = file.lines.first {
            pendingLine.side == .left ? $0.oldNumber == pendingLine.number : $0.newNumber == pendingLine.number
        }?.id
        self.pendingLine = nil

    }

    func retry() {

        guard let repository else { return }

        if self.listingError != nil {
            load(in: repository, selection: self.selection)
        } else if let file = self.selectedFile {
            select(file)
        }

    }

}
