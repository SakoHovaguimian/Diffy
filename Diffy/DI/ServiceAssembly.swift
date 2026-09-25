import Foundation

@MainActor
final class ServiceAssembly {

    let gitService: GitServiceProtocol
    let gitHubService: GitHubServiceProtocol
    let gitHubAccountService: GitHubAccountServiceProtocol
    let runtime: AppRuntime
    let workspaceService: WorkspaceServiceProtocol
    let preferencesService: PreferencesServiceProtocol
    let annotationService: AnnotationServiceProtocol
    let exportService: ReviewExportServiceProtocol
    let textDiffBuilder: TextDiffBuilding
    let fileIconService: FileIconServiceProtocol

    init(runtime: AppRuntime = .current) {

        let isPreview = runtime == .preview
        let preferencesService = PreferencesService(defaults: isPreview ? nil : .standard)
        let notesURL: URL?

        self.runtime = runtime
        self.preferencesService = preferencesService
        self.fileIconService = FileIconService()

        #if DIFFY_LIVE
        if runtime == .live {

            let paths = LiveStoragePaths.standard()
            self.workspaceService = LiveWorkspaceService(
                paths: paths,
                preferencesService: preferencesService
            )
            self.gitService = LiveGitService()
            let configuration = GitHubAppConfiguration.bundled()
            let resolver = GitHubCredentialResolver(configuration: configuration)
            self.gitHubService = LiveGitHubService(configuration: configuration, resolver: resolver)
            self.gitHubAccountService = LiveGitHubAccountService(configuration: configuration, fileURL: paths.gitHubAccountsFile, resolver: resolver)
            notesURL = paths.annotationsFile

        } else {

            self.workspaceService = MockWorkspaceService()
            self.gitService = MockGitService()
            self.gitHubService = MockGitHubService()
            self.gitHubAccountService = MockGitHubAccountService()
            notesURL = nil

        }
        #else
        self.workspaceService = MockWorkspaceService()
        self.gitService = MockGitService()
        self.gitHubService = MockGitHubService()
        self.gitHubAccountService = MockGitHubAccountService()
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
