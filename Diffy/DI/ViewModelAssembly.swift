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
        self.settingsViewModel = SettingsViewModel(
            preferencesService: services.preferencesService,
            fileIconService: services.fileIconService,
            ai: AISettingsViewModel(
                settingsStore: services.aiSettingsStore,
                credentialStore: services.aiCredentialStore,
                commandAvailability: services.aiCommandAvailability,
                modelCatalog: services.aiModelCatalog,
                usesPersistentStorage: services.runtime == .live
            )
        )
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
            textDiffBuilder: self.services.textDiffBuilder,
            makeAIWorkspace: { [services = self.services] review in

                review.patchReview = AIReviewPatchViewModel(
                    repository: review.localRepository,
                    git: services.gitService,
                    request: review.request,
                    latestPullRequest: { [weak review, gitHub = services.gitHubService] in

                        guard let review, let account = review.account else {
                            throw AIReviewError.unavailable("Connect a GitHub account and refresh this PR before applying a saved proposal.")
                        }

                        let latest = try await gitHub.pullRequest(number: review.request.number, link: review.request.link, account: account)

                        if latest.baseSHA != review.details?.summary.baseSHA || latest.headSHA != review.details?.summary.headSHA {

                            review.isStale = true
                            review.aiWorkspace?.clearCurrentDetails()

                        }

                        return latest

                    }
                )

                return AIReviewWorkspaceViewModel(
                    request: review.request,
                    reviewService: services.aiReviewService,
                    historyStore: services.aiHistoryStore,
                    settingsStore: services.aiSettingsStore,
                    credentialStore: services.aiCredentialStore,
                    commandAvailability: services.aiCommandAvailability,
                    modelCatalog: services.aiModelCatalog
                )

            }
        )

    }

    func textDiffViewModel() -> TextDiffViewModel {
        TextDiffViewModel(diffBuilder: self.services.textDiffBuilder)
    }

}
