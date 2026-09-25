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
    let aiSettingsStore: any AISettingsStoreProtocol
    let aiCredentialStore: any AICredentialStoreProtocol
    let aiHistoryStore: any AIHistoryStoreProtocol
    let aiReviewService: any AIReviewServiceProtocol
    let aiCommandAvailability: any AICommandAvailabilityServiceProtocol
    let aiModelCatalog: any AIModelCatalogServiceProtocol

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
            let aiCredentials = LiveAICredentialStore()
            self.aiCredentialStore = aiCredentials
            self.aiSettingsStore = LiveAISettingsStore(fileURL: paths.aiSettingsFile)
            self.aiHistoryStore = LiveAIHistoryStore(rootDirectory: paths.aiHistoryDirectory)
            self.aiReviewService = AIReviewService(
                apiProvider: LiveAIProvider(credentialStore: aiCredentials),
                cliProvider: InstalledCLIProvider()
            )
            self.aiCommandAvailability = InstalledAICommandLocator()
            self.aiModelCatalog = LiveAIModelCatalogService(credentialStore: aiCredentials)

        } else {

            self.workspaceService = MockWorkspaceService()
            self.gitService = MockGitService()
            self.gitHubService = MockGitHubService()
            self.gitHubAccountService = MockGitHubAccountService()
            notesURL = nil
            self.aiSettingsStore = MockAISettingsStore()
            self.aiCredentialStore = MockAICredentialStore()
            self.aiHistoryStore = MockAIHistoryStore()
            self.aiReviewService = AIReviewService(apiProvider: MockAIProvider(), cliProvider: MockAIProvider())
            self.aiCommandAvailability = MockAICommandAvailabilityService()
            self.aiModelCatalog = MockAIModelCatalogService()

        }
        #else
        self.workspaceService = MockWorkspaceService()
        self.gitService = MockGitService()
        self.gitHubService = MockGitHubService()
        self.gitHubAccountService = MockGitHubAccountService()
        notesURL = isPreview ? nil : Self.annotationsURL()
        self.aiSettingsStore = MockAISettingsStore()
        self.aiCredentialStore = MockAICredentialStore()
        self.aiHistoryStore = MockAIHistoryStore()
        self.aiReviewService = AIReviewService(apiProvider: MockAIProvider(), cliProvider: MockAIProvider())
        self.aiCommandAvailability = MockAICommandAvailabilityService()
        self.aiModelCatalog = MockAIModelCatalogService()
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
