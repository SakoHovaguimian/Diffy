import Foundation

protocol AISettingsStoreProtocol: Sendable {
    func loadSettings() async throws -> AISettings
    func saveSettings(_ settings: AISettings) async throws
    func updateModels(_ modelIDs: [String], for provider: AIProviderKind, route: AIExecutionRoute) async throws -> AISettings
    func updateSettings(_ settings: AISettings, baseline: AISettings) async throws -> AISettings
}
