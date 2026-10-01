import Foundation

struct PullRequestRowContent {

    let number: Int
    let title: String
    let author: GitHubUserSummary
    let repositoryFullName: String?
    let updatedAt: Date
    let webURL: URL
    let summary: PullRequestSummary?
    private let initialDraftStatus: Bool

    var lifecycle: PullRequestLifecycle {
        self.summary?.lifecycle ?? .open
    }

    var isDraft: Bool {
        self.summary?.isDraft ?? self.initialDraftStatus
    }

    var statusTitle: String {
        self.summary?.statusTitle ?? (self.isDraft ? "Draft" : "Open")
    }

    init(
        request: AssignedPullRequestSummary,
        details: PullRequestSummary? = nil,
        showsRepository: Bool = true
    ) {

        self.number = request.number
        self.title = details?.title ?? request.title
        self.author = details?.author ?? request.author
        self.repositoryFullName = showsRepository ? request.repositoryFullName : nil
        self.updatedAt = details?.updatedAt ?? request.updatedAt
        self.webURL = request.webURL
        self.summary = details
        self.initialDraftStatus = request.isDraft

    }

    init(
        request: PullRequestSummary,
        repositoryFullName: String?
    ) {

        self.number = request.number
        self.title = request.title
        self.author = request.author
        self.repositoryFullName = repositoryFullName
        self.updatedAt = request.updatedAt
        self.webURL = request.webURL
        self.summary = request
        self.initialDraftStatus = request.isDraft

    }

}
