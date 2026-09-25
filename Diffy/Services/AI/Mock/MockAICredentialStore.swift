import Foundation

actor MockAICredentialStore: AICredentialStoreProtocol {

    /// Preview-only sentinels let the mock review use its in-memory provider
    /// without a real API key or any Keychain access.
    private var keys: [AIProviderKind: String] = Dictionary(
        uniqueKeysWithValues: AIProviderKind.allCases.map { ($0, "mock-preview-only") }
    )

    func hasAPIKey(for provider: AIProviderKind) -> Bool {
        self.keys[provider] != nil
    }

    func apiKey(for provider: AIProviderKind) throws -> String {

        guard let key = self.keys[provider] else {
            throw AIReviewError.missingCredential(provider)
        }

        return key

    }

    func setAPIKey(_ key: String, for provider: AIProviderKind) {
        self.keys[provider] = key
    }

    func removeAPIKey(for provider: AIProviderKind) {
        self.keys.removeValue(forKey: provider)
    }
}
