import Foundation

extension LiveGitHubService {

    func reviewDetails(for request: PullRequestReviewRequest, account: GitHubAccount) async throws -> PullRequestReviewDetails {

        let path = repositoryPath(request.link.coordinate) + "/pulls/\(request.number)"
        let before = try await get(GitHubPullRequestResponse.self, path: path, account: account)
        async let files = reviewPages(PullRequestReviewFile.self, path: path + "/files", account: account, maximumPages: 30)
        async let commits = reviewPages(GitHubPullRequestCommitResponse.self, path: path + "/commits", account: account, maximumPages: 30)
        async let conversation = reviewConversation(for: request, account: account)
        let (loadedFiles, loadedCommits, loadedConversation) = try await (files, commits, conversation)
        let after = try await get(GitHubPullRequestResponse.self, path: path, account: account)

        guard before.head.sha == after.head.sha, before.base.sha == after.base.sha else {
            throw GitHubError.reviewUnavailable("The pull request changed while loading. Refresh to read the latest revision.")
        }

        return PullRequestReviewDetails(
            summary: after.summary,
            body: after.body ?? "",
            changedFileCount: after.changedFiles ?? loadedFiles.count,
            commitCount: after.commits ?? loadedCommits.count,
            commits: loadedCommits.map(\.reviewCommit),
            files: loadedFiles,
            conversation: loadedConversation
        )

    }

    func reviewConversation(for request: PullRequestReviewRequest, account: GitHubAccount) async throws -> [PullRequestConversationEntry] {

        let repository = repositoryPath(request.link.coordinate)
        let pull = repository + "/pulls/\(request.number)"
        async let comments = reviewPages(GitHubConversationResponse.self, path: repository + "/issues/\(request.number)/comments", account: account)
        async let reviews = reviewPages(GitHubConversationResponse.self, path: pull + "/reviews", account: account)
        async let inline = reviewPages(GitHubConversationResponse.self, path: pull + "/comments", account: account)
        let (loadedComments, loadedReviews, loadedInline) = try await (comments, reviews, inline)

        return (
            loadedComments.map { $0.entry(kind: .comment) }
                + loadedReviews.map { $0.entry(kind: .review) }
                + loadedInline.map { $0.entry(kind: .inline) }
        ).sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }

    }

    func submitReview(_ submission: PullRequestReviewSubmission, for request: PullRequestReviewRequest, account: GitHubAccount) async throws {

        let path = repositoryPath(request.link.coordinate) + "/pulls/\(request.number)/reviews"
        let _: GitHubConversationResponse = try await post(path: path, body: submission, account: account)

    }

    func postPullRequestComment(_ body: String, replyingTo commentID: Int?, for request: PullRequestReviewRequest, account: GitHubAccount) async throws {

        let repository = repositoryPath(request.link.coordinate)
        let path = commentID.map { repository + "/pulls/\(request.number)/comments/\($0)/replies" }
            ?? repository + "/issues/\(request.number)/comments"
        let _: GitHubConversationResponse = try await post(path: path, body: ["body": body], account: account)

    }

    private func post<Body: Encodable & Sendable, Response: Decodable & Sendable>(path: String, body: Body, account: GitHubAccount) async throws -> Response {

        guard account.host == self.configuration.host else { throw GitHubError.accountNotFound }
        let credential = try await self.resolver.credential(for: account.id)
        let data = try JSONEncoder().encode(body)
        return try await GitHubHTTPClient(configuration: self.configuration).request(Response.self, path: path, token: credential.accessToken, jsonBody: data)

    }

    private func reviewPages<Value: Decodable & Sendable>(_ type: Value.Type, path: String, account: GitHubAccount, maximumPages: Int? = nil) async throws -> [Value] {

        var result: [Value] = []
        var page = 1

        while true {

            try Task.checkCancellation()
            let values = try await get([Value].self, path: path + "?per_page=100&page=\(page)", account: account)
            result += values
            if values.count < 100 || page == maximumPages { return result }
            page += 1

        }

    }

}
