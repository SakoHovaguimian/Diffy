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

        self.annotations[index] = annotation
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
