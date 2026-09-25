import Foundation
import Security

actor LiveAICredentialStore: AICredentialStoreProtocol {

    private let service = "com.diffy.app.ai-provider"

    func hasAPIKey(for provider: AIProviderKind) -> Bool {
        (try? self.apiKey(for: provider)) != nil
    }

    func apiKey(for provider: AIProviderKind) throws -> String {

        var query = self.query(for: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            throw AIReviewError.missingCredential(provider)
        }

        return key

    }

    func setAPIKey(_ key: String, for provider: AIProviderKind) throws {

        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw AIReviewError.missingCredential(provider)
        }

        let data = Data(trimmed.utf8)
        let query = self.query(for: provider)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if status == errSecItemNotFound {

            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            try self.check(SecItemAdd(item as CFDictionary, nil))

        } else {
            try self.check(status)
        }

    }

    func removeAPIKey(for provider: AIProviderKind) throws {

        let status = SecItemDelete(self.query(for: provider) as CFDictionary)

        if status != errSecItemNotFound {
            try self.check(status)
        }

    }

    private func query(for provider: AIProviderKind) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.service,
            kSecAttrAccount as String: provider.rawValue
        ]
    }

    private func check(_ status: OSStatus) throws {

        guard status == errSecSuccess else {
            throw AIReviewError.storageUnavailable
        }

    }
}
