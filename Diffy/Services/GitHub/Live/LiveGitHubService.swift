import Foundation

struct LiveGitHubService: GitHubServiceProtocol {

    let configuration: GitHubAppConfiguration
    let resolver: GitHubCredentialResolver

    private var client: GitHubHTTPClient {
        GitHubHTTPClient(configuration: self.configuration)
    }

    func currentUser(for account: GitHubAccount) async throws -> GitHubUserSummary {
        try await get(GitHubUserSummary.self, path: "/user", account: account)
    }

    func accessibleRepositories(for account: GitHubAccount, page: Int) async throws -> [GitHubRepositorySummary] {

        let repositories = try await get([GitHubRepositoryResponse].self, path: "/user/repos?per_page=50&sort=updated&page=\(max(1, page))", account: account)
        return repositories.map { $0.summary(host: account.host) }

    }

    func installations(for account: GitHubAccount) async throws -> [GitHubInstallation] {

        var result: [GitHubInstallation] = []
        var page = 1

        while true {

            let response = try await get(InstallationPage.self, path: "/user/installations?per_page=100&page=\(page)", account: account)
            result += response.installations.map { GitHubInstallation(id: $0.id, accountLogin: $0.account.login, accountType: $0.account.type) }

            if response.installations.count < 100 { return result }
            page += 1

        }

    }

    func repositories(for account: GitHubAccount, installationID: Int) async throws -> [GitHubRepositorySummary] {

        var result: [GitHubRepositorySummary] = []
        var page = 1

        while true {

            let response = try await get(RepositoryPage.self, path: "/user/installations/\(installationID)/repositories?per_page=100&page=\(page)", account: account)
            result += response.repositories.map { $0.summary(host: account.host, installationID: installationID) }

            if response.repositories.count < 100 { return result }
            page += 1

        }

    }

    func repository(_ coordinate: GitHubRepositoryCoordinate, account: GitHubAccount) async throws -> GitHubRepositorySummary {

        let response = try await get(GitHubRepositoryResponse.self, path: repositoryPath(coordinate), account: account)
        return response.summary(host: account.host)

    }

    func assignedPullRequests(for account: GitHubAccount) async throws -> AssignedPullRequestListing {
        try await searchedPullRequests(for: account, qualifier: "assignee:")
    }

    func reviewRequestedPullRequests(for account: GitHubAccount) async throws -> AssignedPullRequestListing {
        try await searchedPullRequests(for: account, qualifier: "review-requested:")
    }

    private func searchedPullRequests(for account: GitHubAccount, qualifier: String) async throws -> AssignedPullRequestListing {

        var query = URLComponents()
        query.queryItems = [
            URLQueryItem(name: "q", value: "is:pull-request is:open \(qualifier)\(account.login)"),
            URLQueryItem(name: "sort", value: "updated"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: "100")
        ]

        let response = try await get(
            GitHubAssignedPullRequestSearchResponse.self,
            path: "/search/issues?\(query.percentEncodedQuery ?? "")",
            account: account
        )

        return AssignedPullRequestListing(
            requests: response.items.map {

                var summary = $0.summary
                summary.accountID = account.id
                return summary

            },
            hasMore: response.incompleteResults || response.totalCount > response.items.count
        )

    }

    func unmergedPullRequests(for link: GitHubRepositoryLink, account: GitHubAccount, page: Int) async throws -> PullRequestPage {

        let response = try await get(
            [GitHubPullRequestResponse].self,
            path: repositoryPath(link.coordinate) + "/pulls?state=all&sort=updated&direction=desc&per_page=30&page=\(max(1, page))",
            account: account
        )

        return PullRequestPage(
            pullRequests: response.map(\.summary).filter { $0.lifecycle != .merged },
            hasMore: response.count == 30
        )

    }

    func pullRequest(number: Int, link: GitHubRepositoryLink, account: GitHubAccount) async throws -> PullRequestSummary {
        try await get(GitHubPullRequestResponse.self, path: repositoryPath(link.coordinate) + "/pulls/\(number)", account: account).summary
    }

    func checksSummary(for pullRequest: PullRequestSummary, link: GitHubRepositoryLink, account: GitHubAccount) async -> PullRequestChecksSummary {

        do {

            var runs: [ChecksPage.Check] = []
            var page = 1

            while true {

                let response = try await get(ChecksPage.self, path: repositoryPath(link.coordinate) + "/commits/\(pullRequest.headSHA)/check-runs?per_page=100&page=\(page)", account: account)
                runs += response.checkRuns
                if runs.count >= response.totalCount { break }
                if page >= 10 { return .unavailable }
                page += 1

            }

            let pending = runs.filter { $0.status != "completed" }.count
            let failed = runs.filter { ["failure", "cancelled", "timed_out", "action_required", "startup_failure", "stale"].contains($0.conclusion ?? "") }.count
            let passed = runs.filter { ["success", "neutral", "skipped"].contains($0.conclusion ?? "") }.count
            let state: PullRequestChecksState = failed > 0 ? .failure : (pending > 0 ? .pending : (passed > 0 ? .success : .neutral))
            return PullRequestChecksSummary(state: state, total: runs.count, passed: passed, failed: failed, pending: pending)

        } catch {
            return .unavailable
        }

    }

    func get<Value: Decodable & Sendable>(_ type: Value.Type, path: String, account: GitHubAccount) async throws -> Value {

        guard account.host == self.configuration.host else {
            throw GitHubError.accountNotFound
        }

        let credential = try await self.resolver.credential(for: account.id)
        return try await self.client.request(type, path: path, token: credential.accessToken)

    }

    func repositoryPath(_ coordinate: GitHubRepositoryCoordinate) -> String {

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let owner = coordinate.owner.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        let name = coordinate.name.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return "/repos/\(owner)/\(name)"

    }

    private struct InstallationPage: Decodable, Sendable {

        struct Installation: Decodable, Sendable {

            struct Account: Decodable, Sendable {
                let login: String
                let type: String
            }

            let id: Int
            let account: Account
        }

        let installations: [Installation]
    }

    private struct RepositoryPage: Decodable, Sendable {
        let repositories: [GitHubRepositoryResponse]
    }

    private struct ChecksPage: Decodable, Sendable {

        struct Check: Decodable, Sendable {
            let status: String
            let conclusion: String?
        }

        let checkRuns: [Check]
        let totalCount: Int
    }

}
