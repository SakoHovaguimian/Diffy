import Foundation

actor MockAISettingsStore: AISettingsStoreProtocol {

    private var settings: AISettings = .initial

    func loadSettings() -> AISettings { self.settings }

    func saveSettings(_ settings: AISettings) {
        self.settings = settings
    }

    func updateModels(_ modelIDs: [String], for provider: AIProviderKind, route: AIExecutionRoute) -> AISettings {

        self.settings.setModels(modelIDs, for: provider, route: route)
        return self.settings

    }

    func updateSettings(_ settings: AISettings, baseline: AISettings) -> AISettings {

        self.settings.applyChanges(from: settings, comparedWith: baseline)
        return self.settings

    }
}
