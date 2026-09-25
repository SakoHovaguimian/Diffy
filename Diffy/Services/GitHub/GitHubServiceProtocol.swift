import Foundation

/// GitHub REST access for a connected account. Live implementations resolve the account's
/// Keychain credential internally; tokens never cross this boundary.
protocol GitHubServiceProtocol: Sendable {

    var configuration: GitHubAppConfiguration { get }

    func currentUser(for account: GitHubAccount) async throws -> GitHubUserSummary

    func installations(for account: GitHubAccount) async throws -> [GitHubInstallation]

    func repositories(
        for account: GitHubAccount,
        installationID: Int
    ) async throws -> [GitHubRepositorySummary]

    func repository(
        _ coordinate: GitHubRepositoryCoordinate,
        account: GitHubAccount
    ) async throws -> GitHubRepositorySummary

    /// Open pull requests, requested conditionally with the supplied validators.
    func openPullRequests(
        for link: GitHubRepositoryLink,
        account: GitHubAccount,
        validators: GitHubResourceValidators
    ) async throws -> GitHubFetchResult<[PullRequestSummary]>

    func pullRequest(
        number: Int,
        link: GitHubRepositoryLink,
        account: GitHubAccount
    ) async throws -> PullRequestSummary

    /// Returns `.unavailable` when the App lacks permission to read checks.
    func checksSummary(
        for pullRequest: PullRequestSummary,
        link: GitHubRepositoryLink,
        account: GitHubAccount
    ) async -> PullRequestChecksSummary

}
