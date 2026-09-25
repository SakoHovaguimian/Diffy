import Foundation

struct MockGitHubService: GitHubServiceProtocol {

    let configuration = GitHubAppConfiguration.unconfigured

    func currentUser(for account: GitHubAccount) async throws -> GitHubUserSummary {
        GitHubUserSummary(id: account.userID, login: account.login, name: account.displayName, avatarURL: nil)
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

    func reviewRequestedPullRequests(for account: GitHubAccount) async throws -> AssignedPullRequestListing {
        AssignedPullRequestListing(requests: [], hasMore: false)
    }

    func unmergedPullRequests(for link: GitHubRepositoryLink, account: GitHubAccount, page: Int) async throws -> PullRequestPage {
        PullRequestPage(pullRequests: [], hasMore: false)
    }

    func pullRequest(number: Int, link: GitHubRepositoryLink, account: GitHubAccount) async throws -> PullRequestSummary {
        throw GitHubError.notFound
    }

    func checksSummary(for pullRequest: PullRequestSummary, link: GitHubRepositoryLink, account: GitHubAccount) async -> PullRequestChecksSummary {
        .unavailable
    }

    func reviewDetails(for request: PullRequestReviewRequest, account: GitHubAccount) async throws -> PullRequestReviewDetails {
        throw GitHubError.reviewUnavailable("GitHub reviews are available in Diffy Live.")
    }

    func completeReviewFiles(
        for request: PullRequestReviewRequest,
        account: GitHubAccount,
        files: [PullRequestReviewFile],
        baseSHA: String,
        headSHA: String
    ) async throws -> [AIFileSnapshot] {
        throw GitHubError.reviewUnavailable("Complete pull request diffs are available in Diffy Live.")
    }

    func reviewConversation(for request: PullRequestReviewRequest, account: GitHubAccount) async throws -> [PullRequestConversationEntry] {
        []
    }

    func submitReview(_ submission: PullRequestReviewSubmission, for request: PullRequestReviewRequest, account: GitHubAccount) async throws {
        throw GitHubError.reviewUnavailable("The Mock app cannot publish GitHub reviews.")
    }

    func postPullRequestComment(_ body: String, replyingTo commentID: Int?, for request: PullRequestReviewRequest, account: GitHubAccount) async throws {
        throw GitHubError.reviewUnavailable("The Mock app cannot publish GitHub comments.")
    }

}
