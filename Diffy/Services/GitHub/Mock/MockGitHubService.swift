import Foundation

struct MockGitHubService: GitHubServiceProtocol {

    let configuration = GitHubAppConfiguration.unconfigured

    func currentUser(for account: GitHubAccount) async throws -> GitHubUserSummary {
        GitHubUserSummary(id: account.userID, login: account.login, name: account.displayName)
    }

    func accessibleRepositories(for account: GitHubAccount, page: Int) async throws -> [GitHubRepositorySummary] {
        []
    }

    func installations(for account: GitHubAccount) async throws -> [GitHubInstallation] {
        []
    }

    func repositories(for account: GitHubAccount, installationID: Int) async throws -> [GitHubRepositorySummary] {
        []
    }

    func repository(_ coordinate: GitHubRepositoryCoordinate, account: GitHubAccount) async throws -> GitHubRepositorySummary {
        throw GitHubError.notFound
    }

    func assignedPullRequests(for account: GitHubAccount) async throws -> AssignedPullRequestListing {
        AssignedPullRequestListing(requests: [], hasMore: false)
    }

    func openPullRequests(for link: GitHubRepositoryLink, account: GitHubAccount, validators: GitHubResourceValidators) async throws -> GitHubFetchResult<[PullRequestSummary]> {
        GitHubFetchResult(value: [], validators: .none)
    }

    func pullRequest(number: Int, link: GitHubRepositoryLink, account: GitHubAccount) async throws -> PullRequestSummary {
        throw GitHubError.notFound
    }

    func checksSummary(for pullRequest: PullRequestSummary, link: GitHubRepositoryLink, account: GitHubAccount) async -> PullRequestChecksSummary {
        .unavailable
    }

}
