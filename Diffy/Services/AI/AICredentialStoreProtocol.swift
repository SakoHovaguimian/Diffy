import Foundation

protocol AICredentialStoreProtocol: Sendable {
    func hasAPIKey(for provider: AIProviderKind) async -> Bool
    func setAPIKey(_ key: String, for provider: AIProviderKind) async throws
    func removeAPIKey(for provider: AIProviderKind) async throws
    func apiKey(for provider: AIProviderKind) async throws -> String
}
