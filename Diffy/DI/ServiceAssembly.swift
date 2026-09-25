import Foundation

@MainActor
final class ServiceAssembly {

    let runtime: AppRuntime
    let workspaceService: WorkspaceServiceProtocol
    let preferencesService: PreferencesServiceProtocol
    let annotationService: AnnotationServiceProtocol
    let exportService: ReviewExportServiceProtocol
    let textDiffBuilder: TextDiffBuilding

    init(runtime: AppRuntime = .current) {

        let isPreview = runtime == .preview
        let preferencesService = PreferencesService(defaults: isPreview ? nil : .standard)
        let notesURL: URL?

        self.runtime = runtime
        self.preferencesService = preferencesService

        #if DIFFY_LIVE
        if runtime == .live {

            let paths = LiveStoragePaths.standard()
            self.workspaceService = LiveWorkspaceService(
                paths: paths,
                preferencesService: preferencesService
            )
            notesURL = paths.annotationsFile

        } else {

            self.workspaceService = MockWorkspaceService()
            notesURL = nil

        }
        #else
        self.workspaceService = MockWorkspaceService()
        notesURL = isPreview ? nil : Self.annotationsURL()
        #endif

        self.exportService = ReviewExportService()
        self.textDiffBuilder = MockTextDiffBuilder()
        self.annotationService = AnnotationService(fileURL: notesURL)

    }

    private static func annotationsURL() -> URL? {

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return support?.appendingPathComponent("Diffy/annotations-v1.json")

    }

}
