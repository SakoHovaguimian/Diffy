import Foundation

@MainActor
final class ViewModelAssembly {

    private let services: ServiceAssembly
    let settingsViewModel: SettingsViewModel
    let reviewViewModel: ReviewViewModel

    init(services: ServiceAssembly) {

        self.services = services
        self.settingsViewModel = SettingsViewModel(preferencesService: services.preferencesService)
        self.reviewViewModel = ReviewViewModel(
            annotationService: services.annotationService,
            exportService: services.exportService
        )

    }

    func workspaceViewModel() -> WorkspaceViewModel {

        WorkspaceViewModel(
            runtime: self.services.runtime,
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
