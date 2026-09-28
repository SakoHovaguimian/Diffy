import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ViewModel {

    let loggerName = "SETTINGS_VIEW_MODEL"
    private let preferencesService: PreferencesServiceProtocol
    let fileIconService: FileIconServiceProtocol
    let ai: AISettingsViewModel
    @Published private(set) var hasSeenTutorial: Bool

    @Published var editor: EditorPreferences {
        didSet {
            self.preferencesService.save(self.editor, key: "editor.v1")
            self.preferencesService.save(self.editor.collapseUnchanged, key: "defaultDiffView.changes.v1")
        }
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

    @Published var fileNavigationDefaults: FileNavigationDefaults {
        didSet { self.preferencesService.save(self.fileNavigationDefaults, key: FileNavigationDefaults.storageKey) }
    }

    init(
        preferencesService: PreferencesServiceProtocol,
        fileIconService: FileIconServiceProtocol,
        ai: AISettingsViewModel
    ) {

        self.preferencesService = preferencesService
        self.fileIconService = fileIconService
        self.ai = ai
        self.hasSeenTutorial = preferencesService.load(Bool.self, key: "tutorial.completed.v1") ?? false
        self.fileIconTheme = preferencesService.load(FileIconTheme.self, key: "fileIcons.theme.v1") ?? .material
        var editor = preferencesService.load(EditorPreferences.self, key: "editor.v1") ?? EditorPreferences()
        editor.collapseUnchanged = preferencesService.load(Bool.self, key: "defaultDiffView.changes.v1") ?? true
        self.editor = editor
        var appearance = preferencesService.load(AppearancePreferences.self, key: "appearance.v1") ?? AppearancePreferences()
        appearance.sidebarWidth = max(214, appearance.sidebarWidth)
        self.appearance = appearance
        self.diffVisualization = preferencesService.load(DiffVisualizationPreferences.self, key: "diffVisualization.v1") ?? DiffVisualizationPreferences()
        self.fileNavigationDefaults = preferencesService.load(FileNavigationDefaults.self, key: FileNavigationDefaults.storageKey) ?? FileNavigationDefaults()

    }

    // MARK: - Defaults

    func completeTutorial() {

        guard !self.hasSeenTutorial else { return }
        self.hasSeenTutorial = true
        self.preferencesService.save(true, key: "tutorial.completed.v1")

    }

    func resetAppearance() {

        self.appearance = AppearancePreferences()
        self.fileIconTheme = .material

    }

    func resetEditor() {
        self.editor = EditorPreferences()
        self.fileNavigationDefaults = FileNavigationDefaults()
    }

}
