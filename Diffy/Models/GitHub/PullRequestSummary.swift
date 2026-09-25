import Foundation

struct PullRequestSummary: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let author: GitHubUserSummary
    let assignees: [GitHubUserSummary]
    let requestedReviewers: [GitHubUserSummary]
    let requestedTeams: [GitHubTeamSummary]
    let isDraft: Bool
    let lifecycle: PullRequestLifecycle
    let baseRef: String
    let baseSHA: String
    let headRef: String
    let headSHA: String
    var headRepositoryFullName: String?
    let createdAt: Date
    let updatedAt: Date
    let webURL: URL
    var checks: PullRequestChecksSummary?

    var statusTitle: String {
        self.isDraft && self.lifecycle == .open ? "Draft" : self.lifecycle.title
    }

    func isFromFork(of baseFullName: String) -> Bool {

        guard let headRepositoryFullName = self.headRepositoryFullName else {
            return true
        }

        return headRepositoryFullName.caseInsensitiveCompare(baseFullName) != .orderedSame

    }

    func isAuthored(by login: String) -> Bool {
        self.author.login.caseInsensitiveCompare(login) == .orderedSame
    }

    func isAssigned(to login: String) -> Bool {
        self.assignees.contains { $0.login.caseInsensitiveCompare(login) == .orderedSame }
    }

    /// Direct user review requests. Team requests are listed but not matched because
    /// team membership requires additional organization permissions.
    func requestsReview(from login: String) -> Bool {
        self.requestedReviewers.contains { $0.login.caseInsensitiveCompare(login) == .orderedSame }
    }
}
