import SwiftUI
import Combine

@MainActor
final class ReviewViewModel: ViewModel {

    let loggerName = "REVIEW_VIEW_MODEL"
    private let annotationService: AnnotationServiceProtocol
    private let exportService: ReviewExportServiceProtocol
    private var deletedAnnotations: [CodeAnnotation] = []

    @Published private(set) var annotations: [CodeAnnotation]
    @Published var errorMessage: String?

    init(
        annotationService: AnnotationServiceProtocol,
        exportService: ReviewExportServiceProtocol
    ) {

        self.annotationService = annotationService
        self.exportService = exportService
        self.annotations = []

        do {
            self.annotations = try annotationService.loadAnnotations()
        } catch {
            self.errorMessage = "Saved notes could not be read. The original file will not be overwritten. \(error.localizedDescription)"
        }

    }

    // MARK: - Annotations

    func add(_ annotation: CodeAnnotation) {

        self.annotations.append(annotation)
        persist()

    }

    func update(_ annotation: CodeAnnotation) {

        guard let index = self.annotations.firstIndex(where: { $0.id == annotation.id }) else {
            return
        }

        var updated = annotation
        updated.updatedAt = Date()
        if updated.isResolved {
            updated.needsReviewReason = nil
            updated.needsReviewSince = nil
            updated.reviewTargetSource = nil
        }
        self.annotations[index] = updated
        persist()

    }

    func remove(_ annotation: CodeAnnotation) {

        self.deletedAnnotations = [annotation]
        self.annotations.removeAll { $0.id == annotation.id }
        persist()

    }

    func undoDelete() {

        guard !self.deletedAnnotations.isEmpty else {
            return
        }

        self.annotations.append(contentsOf: self.deletedAnnotations)
        self.deletedAnnotations = []
        persist()

    }

    var canUndoDelete: Bool {
        !self.deletedAnnotations.isEmpty
    }

    func removeAll(projectID: String) {

        self.deletedAnnotations = self.annotations.filter { $0.projectID == projectID }
        self.annotations.removeAll { $0.projectID == projectID }
        persist()

    }

    func removeAll() {

        guard !self.annotations.isEmpty else { return }
        self.deletedAnnotations = self.annotations
        self.annotations.removeAll()
        persist()

    }

    func markNeedsReview(
        ids: Set<UUID>,
        reason: AnnotationReviewReason,
        targetSourceByID: [UUID: String] = [:]
    ) {

        guard !ids.isEmpty else { return }
        var didChange = false

        for index in self.annotations.indices where ids.contains(self.annotations[index].id) {

            let target = targetSourceByID[self.annotations[index].id]
            guard !self.annotations[index].isResolved,
                  target == nil || self.annotations[index].lastReviewedSource != target,
                  self.annotations[index].needsReviewReason != reason || self.annotations[index].reviewTargetSource != target else { continue }
            self.annotations[index].needsReviewReason = reason
            self.annotations[index].needsReviewSince = Date()
            self.annotations[index].reviewTargetSource = target
            self.annotations[index].updatedAt = Date()
            didChange = true

        }

        if didChange { persist() }

    }

    func markReviewed(_ annotation: CodeAnnotation) {

        var updated = annotation
        updated.lastReviewedSource = updated.reviewTargetSource ?? updated.lastReviewedSource
        updated.needsReviewReason = nil
        updated.needsReviewSince = nil
        updated.reviewTargetSource = nil
        update(updated)

    }

    func markChangedSources(projectID: String, comparison: String, files: [DiffFile]) {

        guard !files.isEmpty else { return }
        let filesByPath = Dictionary(files.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
        let changed = self.annotations.compactMap { annotation -> (UUID, String)? in

            guard annotation.projectID == projectID,
                  annotation.comparison == comparison,
                  annotation.source.hasPrefix("git/"),
                  !annotation.isResolved,
                  let file = filesByPath[annotation.filePath] ?? files.first(where: { $0.originalPath == annotation.filePath }),
                  let currentSource = AnnotationSourceMatcher.currentSnippet(for: annotation, in: file),
                  currentSource != annotation.snippet,
                  currentSource != annotation.lastReviewedSource else { return nil }

            return (annotation.id, currentSource)

        }

        markNeedsReview(
            ids: Set(changed.map(\.0)),
            reason: .sourceChanged,
            targetSourceByID: Dictionary(uniqueKeysWithValues: changed)
        )

    }

    func export(_ annotations: [CodeAnnotation], scope: String) -> String {
        self.exportService.markdown(annotations: annotations, scope: scope)
    }

    private func persist() {

        do {

            try self.annotationService.saveAnnotations(self.annotations)
            self.errorMessage = nil

        } catch {
            self.errorMessage = "Your notes are in memory, but could not be saved: \(error.localizedDescription)"
        }

    }

}
