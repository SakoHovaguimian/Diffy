import Foundation

@MainActor
final class LiveGitHubAccountService: GitHubAccountServiceProtocol {

    let configuration: GitHubAppConfiguration
    private let client: GitHubHTTPClient
    private let resolver: GitHubCredentialResolver
    private let credentials = GitHubCredentialStore()
    private let fileURL: URL
    private var accounts: [GitHubAccount] = []
    private var storageError: Error?

    init(
        configuration: GitHubAppConfiguration,
        fileURL: URL,
        resolver: GitHubCredentialResolver
    ) {

        self.configuration = configuration
        self.resolver = resolver
        self.client = GitHubHTTPClient(configuration: configuration)
        self.fileURL = fileURL

        if FileManager.default.fileExists(atPath: fileURL.path) {

            do {
                self.accounts = try JSONDecoder().decode([GitHubAccount].self, from: Data(contentsOf: fileURL))
            } catch {
                self.storageError = error
            }

        }

    }

    func loadAccounts() -> [GitHubAccount] {

        self.accounts.map { account in

            var account = account

            if let credential = try? self.credentials.read(accountID: account.id, allowExpired: true) {

                let expired = credential.expiresAt.map { $0 <= Date() } ?? false
                let canRefresh = credential.refreshToken != nil && (credential.refreshTokenExpiresAt.map { $0 > Date() } ?? true)
                if expired && !canRefresh { account.status = .reauthorizationRequired }

            } else {
                account.status = .reauthorizationRequired
            }

            return account

        }

    }

    func beginDeviceAuthorization(reconnecting account: GitHubAccount?) async throws -> GitHubDeviceAuthorization {

        guard let clientID = self.configuration.clientID, self.configuration.isConfigured else {
            throw GitHubError.notConfigured
        }

        let response = try await self.client.request(GitHubDeviceResponse.self, path: "/login/device/code", form: ["client_id": clientID], web: true)

        guard response.verificationUri.scheme == "https", response.verificationUri.host == self.configuration.host else {
            throw GitHubError.invalidResponse("Unexpected sign-in address.")
        }

        return GitHubDeviceAuthorization(id: UUID(), host: self.configuration.host, userCode: response.userCode, verificationURL: response.verificationUri, deviceCode: response.deviceCode, expiresAt: Date().addingTimeInterval(response.expiresIn), pollingInterval: max(5, response.interval), reconnectingAccountID: account?.id)

    }

    func completeDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) async throws -> GitHubAccount {

        var interval = authorization.pollingInterval

        while Date() < authorization.expiresAt {

            try await Task.sleep(for: .seconds(interval))
            try Task.checkCancellation()
            let response = try await self.client.request(GitHubTokenResponse.self, path: "/login/oauth/access_token", form: [
                "client_id": self.configuration.clientID ?? "",
                "device_code": authorization.deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
            ], web: true)

            if let token = response.accessToken {

                let credential = GitHubCredential(
                    accessToken: token,
                    expiresAt: response.expiresIn.map { Date().addingTimeInterval($0) },
                    isPersonalToken: false,
                    refreshToken: response.refreshToken,
                    refreshTokenExpiresAt: response.refreshTokenExpiresIn.map { Date().addingTimeInterval($0) }
                )
                return try await connect(credential, reconnectingID: authorization.reconnectingAccountID)

            }

            switch response.error {

            case "authorization_pending": continue
            case "slow_down": interval += 5
            case "expired_token": throw GitHubError.authorizationExpired
            case "access_denied": throw GitHubError.authorizationDenied
            default: throw GitHubError.invalidResponse("Restart GitHub sign-in.")

            }

        }

        throw GitHubError.authorizationExpired

    }

    func signInUsingCLI(
        reconnecting account: GitHubAccount?,
        challenge: @escaping @Sendable (GitHubSignInChallenge) -> Void
    ) async throws -> GitHubAccount {

        let credential = try await GitHubCLIAuthorizer().authorize(host: self.configuration.host, challenge: challenge)
        try Task.checkCancellation()
        return try await connect(credential, reconnectingID: account?.id)

    }

    func connect(personalAccessToken: String) async throws -> GitHubAccount {

        let token = personalAccessToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty else {
            throw GitHubError.invalidResponse("Enter a personal access token.")
        }

        return try await connect(GitHubCredential(accessToken: token, expiresAt: nil, isPersonalToken: true), reconnectingID: nil)

    }

    private func connect(_ credential: GitHubCredential, reconnectingID: String?) async throws -> GitHubAccount {

        try verifyStorage()
        let user = try await self.client.request(GitHubUserSummary.self, path: "/user", token: credential.accessToken)
        try Task.checkCancellation()

        if let reconnectingID, let expected = self.accounts.first(where: { $0.id == reconnectingID }), expected.userID != user.id {
            throw GitHubError.forbidden("Sign in as @\(expected.login) to reconnect this account.")
        }

        let existing = self.accounts.first { $0.userID == user.id && $0.host == self.configuration.host }
        let account = GitHubAccount(id: existing?.id ?? UUID().uuidString, host: self.configuration.host, userID: user.id, login: user.login, displayName: user.name, connectedAt: existing?.connectedAt ?? Date(), status: .connected)
        let updated = self.accounts.filter { $0.id != account.id } + [account]
        try self.credentials.write(credential, accountID: account.id)
        do {
            try persist(updated)
        } catch {

            if existing == nil { try? self.credentials.remove(accountID: account.id) }
            throw error

        }

        return account

    }

    func refreshAccount(_ account: GitHubAccount) async throws -> GitHubAccount {

        let credential = try await self.resolver.credential(for: account.id)
        let user = try await self.client.request(GitHubUserSummary.self, path: "/user", token: credential.accessToken)
        var refreshed = account
        refreshed.login = user.login
        refreshed.displayName = user.name
        refreshed.status = .connected
        try persist(self.accounts.map { $0.id == account.id ? refreshed : $0 })
        return refreshed

    }

    func markRequiresReauthorization(_ account: GitHubAccount) throws {

        let updated = self.accounts.map { saved in

            var saved = saved
            if saved.id == account.id { saved.status = .reauthorizationRequired }
            return saved

        }
        try persist(updated)

    }

    func removeAccount(_ account: GitHubAccount) async throws {

        try verifyStorage()
        await self.resolver.cancelRefresh(for: account.id)
        try self.credentials.remove(accountID: account.id)
        try persist(self.accounts.filter { $0.id != account.id })

    }

    private func verifyStorage() throws {

        guard self.storageError == nil else {
            throw GitHubError.credentialStorage("The saved account list is unreadable and has been protected from overwrite.")
        }

    }

    private func persist(_ accounts: [GitHubAccount]) throws {

        try verifyStorage()
        try FileManager.default.createDirectory(at: self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(accounts).write(to: self.fileURL, options: .atomic)
        self.accounts = accounts

    }

}
