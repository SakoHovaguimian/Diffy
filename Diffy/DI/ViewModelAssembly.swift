import Foundation

@MainActor
final class ViewModelAssembly {

    private let services: ServiceAssembly
    let settingsViewModel: SettingsViewModel
    let reviewViewModel: ReviewViewModel
    let gitHubAccountsViewModel: GitHubAccountsViewModel

    init(services: ServiceAssembly) {

        self.services = services
        self.gitHubAccountsViewModel = GitHubAccountsViewModel(
            runtime: services.runtime,
            accountService: services.gitHubAccountService,
            gitHub: services.gitHubService,
            git: services.gitService,
            workspace: services.workspaceService
        )
        self.settingsViewModel = SettingsViewModel(preferencesService: services.preferencesService)
        self.reviewViewModel = ReviewViewModel(
            annotationService: services.annotationService,
            exportService: services.exportService
        )

    }

    func workspaceViewModel() -> WorkspaceViewModel {

        WorkspaceViewModel(
            runtime: self.services.runtime,
            repositoryViewModel: RepositoryViewModel(runtime: self.services.runtime, git: self.services.gitService, gitHub: self.services.gitHubService, accounts: self.services.gitHubAccountService, diffBuilder: self.services.textDiffBuilder),
            overviewViewModel: WorkspaceOverviewViewModel(runtime: self.services.runtime, git: self.services.gitService, gitHub: self.services.gitHubService),
            workspaceService: self.services.workspaceService,
            preferencesService: self.services.preferencesService,
            fileNavigatorViewModel: FileNavigatorViewModel(preferencesService: self.services.preferencesService),
            textDiffBuilder: self.services.textDiffBuilder
        )

    }

    func textDiffViewModel() -> TextDiffViewModel {
        TextDiffViewModel(diffBuilder: self.services.textDiffBuilder)
    }

}
