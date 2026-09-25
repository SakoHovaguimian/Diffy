import Foundation

@MainActor
final class ServiceAssembly {

    let workspaceService: WorkspaceServiceProtocol
    let preferencesService: PreferencesServiceProtocol
    let annotationService: AnnotationServiceProtocol
    let exportService: ReviewExportServiceProtocol
    let textDiffBuilder: TextDiffBuilding

    init(isPreview: Bool = false) {

        self.workspaceService = MockWorkspaceService()
        self.preferencesService = PreferencesService(defaults: isPreview ? nil : .standard)
        self.exportService = ReviewExportService()
        self.textDiffBuilder = MockTextDiffBuilder()

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let notesURL = support?.appendingPathComponent("Diffy/annotations-v1.json")
        self.annotationService = AnnotationService(fileURL: isPreview ? nil : notesURL)

    }

}
