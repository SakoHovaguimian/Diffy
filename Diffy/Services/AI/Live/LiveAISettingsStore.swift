import Foundation

actor LiveAISettingsStore: AISettingsStoreProtocol {

    private let fileURL: URL
    private var readError = false
    private var hasLoaded = false

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func loadSettings() throws -> AISettings {

        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            self.hasLoaded = true
            return .initial
        }

        do {
            let data = try Data(contentsOf: self.fileURL)
            let settings = try JSONDecoder().decode(AISettings.self, from: data)
            self.hasLoaded = true
            return settings
        } catch {
            self.readError = true
            throw AIReviewError.storageUnavailable
        }

    }

    func saveSettings(_ settings: AISettings) throws {

        guard !self.readError else {
            throw AIReviewError.storageUnavailable
        }

        if !self.hasLoaded {
            _ = try self.loadSettings()
        }

        do {

            let directory = self.fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            let data = try JSONEncoder().encode(settings)
            try data.write(to: self.fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.fileURL.path)

        } catch {
            throw AIReviewError.storageUnavailable
        }

    }

    func updateModels(_ modelIDs: [String], for provider: AIProviderKind, route: AIExecutionRoute) throws -> AISettings {

        var settings = try self.loadSettings()
        settings.setModels(modelIDs, for: provider, route: route)
        try self.saveSettings(settings)

        return settings

    }

    func updateSettings(_ settings: AISettings, baseline: AISettings) throws -> AISettings {

        var latest = try self.loadSettings()
        latest.applyChanges(from: settings, comparedWith: baseline)
        try self.saveSettings(latest)

        return latest

    }
}
