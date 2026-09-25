import SwiftUI

@MainActor
final class MockAssembler {

    static let shared = MockAssembler()

    private let assembler: AppAssembler

    private init() {

        self.assembler = AppAssembler(runtime: .preview)
        self.assembler.viewModels.reviewViewModel.add(MockPreviewFixtures.annotation)

    }

    func resolve<Value>(_ type: Value.Type) -> Value {

        let resolved: Any

        if type == WorkspaceViewModel.self {
            resolved = self.assembler.viewModels.workspaceViewModel()
        } else if type == FileNavigatorViewModel.self {
            resolved = FileNavigatorViewModel(preferencesService: self.assembler.services.preferencesService)
        } else if type == TextDiffViewModel.self {
            resolved = self.assembler.viewModels.textDiffViewModel()
        } else if type == MergeViewModel.self {
            resolved = MergeViewModel()
        } else if type == SettingsViewModel.self {
            resolved = self.assembler.viewModels.settingsViewModel
        } else if type == ReviewViewModel.self {
            resolved = self.assembler.viewModels.reviewViewModel
        } else if type == WorkspaceServiceProtocol.self {
            resolved = self.assembler.services.workspaceService
        } else if type == PreferencesServiceProtocol.self {
            resolved = self.assembler.services.preferencesService
        } else if type == AnnotationServiceProtocol.self {
            resolved = self.assembler.services.annotationService
        } else if type == ReviewExportServiceProtocol.self {
            resolved = self.assembler.services.exportService
        } else {
            preconditionFailure("No mock registration for \(type)")
        }

        guard let value = resolved as? Value else {
            preconditionFailure("Invalid mock registration for \(type)")
        }

        return value

    }

}

@MainActor
func mockResolve<Value>(_ type: Value.Type) -> Value {
    MockAssembler.shared.resolve(type)
}

@MainActor
func mockResolveWorkspace(mode: ComparisonMode) -> WorkspaceViewModel {

    let workspace = mockResolve(WorkspaceViewModel.self)
    workspace.selectMode(mode)

    return workspace

}
