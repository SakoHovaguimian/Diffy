import Foundation

@MainActor
final class MockGitHubAccountService: GitHubAccountServiceProtocol {

    let configuration = GitHubAppConfiguration.unconfigured

    func loadAccounts() -> [GitHubAccount] {
        []
    }

    func signInUsingCLI(
        reconnecting account: GitHubAccount?,
        challenge: @escaping @Sendable (GitHubSignInChallenge) -> Void
    ) async throws -> GitHubAccount {
        throw GitHubError.forbidden("Open Diffy Live to connect GitHub.")
    }

    func connect(personalAccessToken: String) async throws -> GitHubAccount {
        throw GitHubError.forbidden("Open Diffy Live to connect a GitHub account.")
    }

    func beginDeviceAuthorization(reconnecting account: GitHubAccount?) async throws -> GitHubDeviceAuthorization {
        throw GitHubError.notConfigured
    }

    func completeDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) async throws -> GitHubAccount {
        throw GitHubError.notConfigured
    }

    func refreshAccount(_ account: GitHubAccount) async throws -> GitHubAccount {
        account
    }

    func markRequiresReauthorization(_ account: GitHubAccount) throws {}

    func removeAccount(_ account: GitHubAccount) async throws {}

}
