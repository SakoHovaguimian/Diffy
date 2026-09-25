import Foundation
import Security

struct GitHubCredentialStore: Sendable {

    private let service = "com.diffy.app.github"

    func read(accountID: String, allowExpired: Bool = false) throws -> GitHubCredential {

        var query = query(accountID: accountID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw GitHubError.reauthorizationRequired(accountID: accountID)
        }

        let credential = try JSONDecoder().decode(GitHubCredential.self, from: data)

        guard allowExpired || (credential.expiresAt.map({ $0 > Date().addingTimeInterval(30) }) ?? true) else {
            throw GitHubError.reauthorizationRequired(accountID: accountID)
        }

        return credential

    }

    func write(_ credential: GitHubCredential, accountID: String) throws {

        let data = try JSONEncoder().encode(credential)
        let query = query(accountID: accountID)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if status == errSecItemNotFound {

            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            try check(SecItemAdd(item as CFDictionary, nil))

        } else {
            try check(status)
        }

    }

    func remove(accountID: String) throws {

        let status = SecItemDelete(query(accountID: accountID) as CFDictionary)

        if status != errSecItemNotFound {
            try check(status)
        }

    }

    private func query(accountID: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: self.service, kSecAttrAccount as String: accountID]
    }

    private func check(_ status: OSStatus) throws {

        guard status == errSecSuccess else {
            throw GitHubError.credentialStorage("macOS returned error \(status).")
        }

    }

}
