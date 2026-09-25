import Foundation

/// Shares in-flight refreshes so a rotating refresh token is used only once.
actor GitHubCredentialResolver {

    private let configuration: GitHubAppConfiguration
    private let store = GitHubCredentialStore()
    private var refreshes: [String: Task<GitHubCredential, Error>] = [:]

    init(configuration: GitHubAppConfiguration) {
        self.configuration = configuration
    }

    func cancelRefresh(for accountID: String) {

        self.refreshes[accountID]?.cancel()
        self.refreshes[accountID] = nil

    }

    func credential(for accountID: String) async throws -> GitHubCredential {

        if let pending = self.refreshes[accountID] { return try await pending.value }
        let credential = try self.store.read(accountID: accountID, allowExpired: true)

        guard let expiry = credential.expiresAt, expiry < Date().addingTimeInterval(60) else {
            return credential
        }

        guard let refreshToken = credential.refreshToken,
              credential.refreshTokenExpiresAt.map({ $0 > Date() }) ?? true,
              let clientID = self.configuration.clientID else {
            throw GitHubError.reauthorizationRequired(accountID: accountID)
        }

        let client = GitHubHTTPClient(configuration: self.configuration)
        let task = Task {

            let response = try await client.request(GitHubTokenResponse.self, path: "/login/oauth/access_token", form: [
                "client_id": clientID,
                "grant_type": "refresh_token",
                "refresh_token": refreshToken
            ], web: true)

            guard let token = response.accessToken else {
                throw GitHubError.reauthorizationRequired(accountID: accountID)
            }

            let refreshed = GitHubCredential(
                accessToken: token,
                expiresAt: response.expiresIn.map { Date().addingTimeInterval($0) },
                isPersonalToken: false,
                refreshToken: response.refreshToken,
                refreshTokenExpiresAt: response.refreshTokenExpiresIn.map { Date().addingTimeInterval($0) }
            )
            try Task.checkCancellation()
            try self.store.write(refreshed, accountID: accountID)
            return refreshed

        }
        self.refreshes[accountID] = task
        defer { self.refreshes[accountID] = nil }
        return try await task.value

    }

}
