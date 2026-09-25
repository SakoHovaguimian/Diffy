import Foundation

/// Connected GitHub accounts. Device Flow authorization, Keychain credentials, and
/// non-secret account metadata are owned by implementations of this protocol.
@MainActor
protocol GitHubAccountServiceProtocol: AnyObject {

    var configuration: GitHubAppConfiguration { get }

    func loadAccounts() -> [GitHubAccount]

    func connect(personalAccessToken: String) async throws -> GitHubAccount

    func signInUsingCLI(
        reconnecting account: GitHubAccount?,
        challenge: @escaping @Sendable (GitHubSignInChallenge) -> Void
    ) async throws -> GitHubAccount

    /// Requests a user code. Pass an account to reconnect it instead of adding a new one.
    func beginDeviceAuthorization(reconnecting account: GitHubAccount?) async throws -> GitHubDeviceAuthorization

    /// Polls until the user approves, the code expires, or the task is cancelled.
    func completeDeviceAuthorization(_ authorization: GitHubDeviceAuthorization) async throws -> GitHubAccount

    /// Refreshes the credential if needed and reloads the account profile.
    func refreshAccount(_ account: GitHubAccount) async throws -> GitHubAccount

    func markRequiresReauthorization(_ account: GitHubAccount) throws

    /// Deletes the account's Keychain credential and metadata.
    func removeAccount(_ account: GitHubAccount) async throws

}
