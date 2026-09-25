import Foundation

struct GitHubPullRequestResponse: Decodable, Sendable {

    struct Reference: Decodable, Sendable {
        let ref: String
        let sha: String
        let repo: Repository?
    }

    struct Repository: Decodable, Sendable {
        let fullName: String
    }

    let id: Int
    let number: Int
    let title: String
    let user: GitHubUserSummary
    let assignees: [GitHubUserSummary]
    let requestedReviewers: [GitHubUserSummary]
    let requestedTeams: [GitHubTeamSummary]
    let draft: Bool
    let state: String
    let mergedAt: Date?
    let base: Reference
    let head: Reference
    let createdAt: Date
    let updatedAt: Date
    let htmlUrl: URL
    let body: String?
    let changedFiles: Int?

    var summary: PullRequestSummary {

        PullRequestSummary(id: self.id, number: self.number, title: self.title, author: self.user, assignees: self.assignees, requestedReviewers: self.requestedReviewers, requestedTeams: self.requestedTeams, isDraft: self.draft, lifecycle: self.mergedAt != nil ? .merged : (self.state == "closed" ? .closedUnmerged : .open), baseRef: self.base.ref, baseSHA: self.base.sha, headRef: self.head.ref, headSHA: self.head.sha, headRepositoryFullName: self.head.repo?.fullName, createdAt: self.createdAt, updatedAt: self.updatedAt, webURL: self.htmlUrl)

    }

}
