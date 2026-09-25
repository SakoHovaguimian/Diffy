import Foundation

/// GitHub REST access for a connected account. Live implementations resolve the account's
/// Keychain credential internally; tokens never cross this boundary.
protocol GitHubServiceProtocol: Sendable {

    var configuration: GitHubAppConfiguration { get }

    func currentUser(for account: GitHubAccount) async throws -> GitHubUserSummary

    func accessibleRepositories(for account: GitHubAccount, page: Int) async throws -> [GitHubRepositorySummary]

    func installations(for account: GitHubAccount) async throws -> [GitHubInstallation]

    func repositories(
        for account: GitHubAccount,
        installationID: Int
    ) async throws -> [GitHubRepositorySummary]

    func repository(
        _ coordinate: GitHubRepositoryCoordinate,
        account: GitHubAccount
    ) async throws -> GitHubRepositorySummary

    /// The most recently updated open pull requests assigned to this account across
    /// repositories visible to it. `hasMore` identifies GitHub's result cap.
    func assignedPullRequests(for account: GitHubAccount) async throws -> AssignedPullRequestListing

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
