import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ViewModel {

    let loggerName = "SETTINGS_VIEW_MODEL"
    private let preferencesService: PreferencesServiceProtocol

    @Published var editor: EditorPreferences {
        didSet { self.preferencesService.save(self.editor, key: "editor.v1") }
    }

    @Published var appearance: AppearancePreferences {
        didSet { self.preferencesService.save(self.appearance, key: "appearance.v1") }
    }

    @Published var diffVisualization: DiffVisualizationPreferences {
        didSet { self.preferencesService.save(self.diffVisualization, key: "diffVisualization.v1") }
    }

    init(preferencesService: PreferencesServiceProtocol) {

        self.preferencesService = preferencesService
        self.editor = preferencesService.load(EditorPreferences.self, key: "editor.v1") ?? EditorPreferences()
        var appearance = preferencesService.load(AppearancePreferences.self, key: "appearance.v1") ?? AppearancePreferences()
        appearance.sidebarWidth = max(214, appearance.sidebarWidth)
        self.appearance = appearance
        self.diffVisualization = preferencesService.load(DiffVisualizationPreferences.self, key: "diffVisualization.v1") ?? DiffVisualizationPreferences()

    }

    // MARK: - Defaults

    func resetAppearance() {
        self.appearance = AppearancePreferences()
    }

    func resetEditor() {
        self.editor = EditorPreferences()
    }

}
