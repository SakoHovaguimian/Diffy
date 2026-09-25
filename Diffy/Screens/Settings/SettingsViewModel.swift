import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ViewModel {

    let loggerName = "SETTINGS_VIEW_MODEL"
    private let preferencesService: PreferencesServiceProtocol
    let fileIconService: FileIconServiceProtocol
    let ai: AISettingsViewModel

    @Published var editor: EditorPreferences {
        didSet { self.preferencesService.save(self.editor, key: "editor.v1") }
    }

    @Published var appearance: AppearancePreferences {
        didSet { self.preferencesService.save(self.appearance, key: "appearance.v1") }
    }

    @Published var fileIconTheme: FileIconTheme {
        didSet { self.preferencesService.save(self.fileIconTheme, key: "fileIcons.theme.v1") }
    }

    @Published var diffVisualization: DiffVisualizationPreferences {
        didSet { self.preferencesService.save(self.diffVisualization, key: "diffVisualization.v1") }
    }

    init(
        preferencesService: PreferencesServiceProtocol,
        fileIconService: FileIconServiceProtocol,
        ai: AISettingsViewModel
    ) {

        self.preferencesService = preferencesService
        self.fileIconService = fileIconService
        self.ai = ai
        self.fileIconTheme = preferencesService.load(FileIconTheme.self, key: "fileIcons.theme.v1") ?? .material
        self.editor = preferencesService.load(EditorPreferences.self, key: "editor.v1") ?? EditorPreferences()
        var appearance = preferencesService.load(AppearancePreferences.self, key: "appearance.v1") ?? AppearancePreferences()
        appearance.sidebarWidth = max(214, appearance.sidebarWidth)
        self.appearance = appearance
        self.diffVisualization = preferencesService.load(DiffVisualizationPreferences.self, key: "diffVisualization.v1") ?? DiffVisualizationPreferences()

    }

    // MARK: - Defaults

    func resetAppearance() {

        self.appearance = AppearancePreferences()
        self.fileIconTheme = .material

    }

    func resetEditor() {
        self.editor = EditorPreferences()
    }

}
