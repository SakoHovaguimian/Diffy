import Foundation
import Combine

@MainActor
final class WorkspaceOverviewViewModel: ViewModel {

    let loggerName = "WORKSPACE_OVERVIEW_VIEW_MODEL"
    private let runtime: AppRuntime
    private let git: GitServiceProtocol
    private let gitHub: GitHubServiceProtocol
    private var refreshID = UUID()

    @Published var gitHubReview: PullRequestReviewViewModel?
    @Published private(set) var activeProjects: [OverviewProjectChange] = []
    @Published private(set) var assignedPullRequests: [AssignedPullRequestSummary] = []
    @Published private(set) var reviewRequestedPullRequests: [AssignedPullRequestSummary] = []
    @Published var assignedSortOrder: OverviewPullRequestSortOrder = .recentlyUpdated
    @Published var reviewRequestedSortOrder: OverviewPullRequestSortOrder = .recentlyUpdated
    @Published var collapsedAssignedGroups: Set<OverviewPullRequestGroupID> = []
    @Published var collapsedReviewRequestedGroups: Set<OverviewPullRequestGroupID> = []
    @Published private(set) var hasMoreAssignedPullRequests = false
    @Published private(set) var hasMoreReviewRequestedPullRequests = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isLoadingProjects = false
    @Published private(set) var isLoadingPullRequests = false
    @Published private(set) var isLoadingAssigned = false
    @Published private(set) var isLoadingReviewRequested = false
    @Published private(set) var hasLoadedProjects = false
    @Published private(set) var hasLoadedAssigned = false
    @Published private(set) var hasLoadedReviewRequested = false
    @Published private(set) var projectError: String?
    @Published private(set) var assignedError: String?
    @Published private(set) var reviewRequestedError: String?

    var sortedAssignedPullRequests: [AssignedPullRequestSummary] {
        self.assignedSortOrder.sorted(self.assignedPullRequests)
    }

    var sortedReviewRequestedPullRequests: [AssignedPullRequestSummary] {
        self.reviewRequestedSortOrder.sorted(self.reviewRequestedPullRequests)
    }

    init(
        runtime: AppRuntime,
        git: GitServiceProtocol,
        gitHub: GitHubServiceProtocol
    ) {

        self.runtime = runtime
        self.git = git
        self.gitHub = gitHub

    }

    func reviewPullRequest(_ request: AssignedPullRequestSummary, accounts: [GitHubAccount]) {

        let parts = request.repositoryFullName.split(separator: "/")
        guard parts.count == 2, let host = request.webURL.host else { return }
        let coordinate = GitHubRepositoryCoordinate(host: host, owner: String(parts[0]), name: String(parts[1]))
        let reviewRequest = PullRequestReviewRequest(
            number: request.number,
            title: request.title,
            webURL: request.webURL,
            link: GitHubRepositoryLink(coordinate: coordinate),
            preferredAccountID: request.accountID
        )
        self.gitHubReview = PullRequestReviewViewModel(request: reviewRequest, accounts: accounts, gitHub: self.gitHub)

    }

    func refresh(projects: [RepositoryProject], accounts: [GitHubAccount]) async {

        let requestID = UUID()
        self.refreshID = requestID
        self.isRefreshing = true
        self.hasLoadedProjects = false
        self.hasLoadedAssigned = false
        self.hasLoadedReviewRequested = false
        self.activeProjects = []
        self.assignedPullRequests = []
        self.reviewRequestedPullRequests = []
        self.hasMoreAssignedPullRequests = false
        self.hasMoreReviewRequestedPullRequests = false
        self.projectError = nil
        self.assignedError = nil
        self.reviewRequestedError = nil

        let repositories = projects.filter { $0.repositoryReference != nil }
        let connectedAccounts = accounts.filter { $0.status == .connected }
        self.isLoadingProjects = !repositories.isEmpty
        self.isLoadingPullRequests = !connectedAccounts.isEmpty
        self.isLoadingAssigned = !connectedAccounts.isEmpty
        self.isLoadingReviewRequested = !connectedAccounts.isEmpty
        self.hasLoadedProjects = repositories.isEmpty
        self.hasLoadedAssigned = connectedAccounts.isEmpty
        self.hasLoadedReviewRequested = connectedAccounts.isEmpty

        if !self.runtime.isLive {

            self.activeProjects = projects.compactMap(mockChange)
            finishRefresh(requestID)
            return

        }

        var remainingProjects = repositories.count
        var remainingAssigned = connectedAccounts.count
        var remainingReviewRequested = connectedAccounts.count
        var failedProjects = 0
        var failedAssigned = 0
        var failedReviewRequested = 0

        await withTaskGroup(of: RefreshResult.self) { group in

            for project in repositories {
                group.addTask { [git] in await Self.readProject(project, git: git) }
            }

            for account in connectedAccounts {
                group.addTask { [gitHub] in await Self.readRequests(account, kind: .assigned, gitHub: gitHub) }
                group.addTask { [gitHub] in await Self.readRequests(account, kind: .reviewRequested, gitHub: gitHub) }
            }

            for await result in group {

                guard self.refreshID == requestID, !Task.isCancelled else {
                    group.cancelAll()
                    return
                }

                switch result {

                case let .project(change):
                    remainingProjects -= 1
                    if let change { self.activeProjects.append(change) }
                    self.activeProjects.sort { $0.project.displayName.localizedStandardCompare($1.project.displayName) == .orderedAscending }

                case .projectFailure:
                    remainingProjects -= 1
                    failedProjects += 1
                    self.projectError = "Couldn’t read \(failedProjects) project\(failedProjects == 1 ? "" : "s"). Check the folder and refresh."

                case let .requests(kind, listing):
                    mergeRequests(listing, kind: kind)
                    if kind == .assigned { remainingAssigned -= 1 }
                    else { remainingReviewRequested -= 1 }

                case let .requestFailure(kind):
                    if kind == .assigned {
                        remainingAssigned -= 1
                        failedAssigned += 1
                        self.assignedError = "Couldn’t load assignments for \(failedAssigned) account\(failedAssigned == 1 ? "" : "s"). Refresh to retry."
                    } else {
                        remainingReviewRequested -= 1
                        failedReviewRequested += 1
                        self.reviewRequestedError = "Couldn’t load review requests for \(failedReviewRequested) account\(failedReviewRequested == 1 ? "" : "s"). Refresh to retry."
                    }

                }

                self.isLoadingProjects = remainingProjects > 0
                self.isLoadingPullRequests = remainingAssigned > 0 || remainingReviewRequested > 0
                self.isLoadingAssigned = remainingAssigned > 0
                self.isLoadingReviewRequested = remainingReviewRequested > 0
                self.hasLoadedProjects = remainingProjects == 0
                self.hasLoadedAssigned = remainingAssigned == 0
                self.hasLoadedReviewRequested = remainingReviewRequested == 0

            }

        }

        guard self.refreshID == requestID, !Task.isCancelled else { return }

        finishRefresh(requestID)

    }

    private func finishRefresh(_ requestID: UUID) {

        guard self.refreshID == requestID else { return }
        self.isRefreshing = false
        self.isLoadingProjects = false
        self.isLoadingPullRequests = false
        self.isLoadingAssigned = false
        self.isLoadingReviewRequested = false
        self.hasLoadedProjects = true
        self.hasLoadedAssigned = true
        self.hasLoadedReviewRequested = true

    }

    private func mergeRequests(_ listing: AssignedPullRequestListing, kind: RequestKind) {

        switch kind {

        case .assigned:
            self.assignedPullRequests = Self.unique(self.assignedPullRequests + listing.requests)
            self.hasMoreAssignedPullRequests = self.hasMoreAssignedPullRequests || listing.hasMore

        case .reviewRequested:
            self.reviewRequestedPullRequests = Self.unique(self.reviewRequestedPullRequests + listing.requests)
            self.hasMoreReviewRequestedPullRequests = self.hasMoreReviewRequestedPullRequests || listing.hasMore

        }

    }

    private static func unique(_ requests: [AssignedPullRequestSummary]) -> [AssignedPullRequestSummary] {

        var seen: Set<String> = []
        return requests.filter { seen.insert($0.id).inserted }.sorted { $0.updatedAt > $1.updatedAt }

    }

    private static func readProject(_ project: RepositoryProject, git: GitServiceProtocol) async -> RefreshResult {

        guard let reference = project.repositoryReference else { return .project(nil) }

        do {

            let snapshot = try await git.snapshot(of: reference, scope: .status, previous: nil)
            let isBehind = (snapshot.upstream?.behind ?? 0) > 0
            guard !snapshot.isClean || isBehind else { return .project(nil) }

            let counts: DiffLineCounts?

            if snapshot.isClean {
                counts = DiffLineCounts(additions: 0, deletions: 0)
            } else if snapshot.changes.filter(\.isUntracked).count > 100 {
                counts = nil
            } else {
                let working = try? await git.patch(in: reference, selection: .workingTree)
                let staged = try? await git.patch(in: reference, selection: .staged)
                if let working, let staged, !working.contains("Binary files "), !staged.contains("Binary files ") {
                    let left = GitPatchParser.lineCounts(working)
                    let right = GitPatchParser.lineCounts(staged)
                    counts = DiffLineCounts(additions: left.additions + right.additions, deletions: left.deletions + right.deletions)
                } else {
                    counts = nil
                }
            }

            return .project(OverviewProjectChange(
                project: project,
                branchName: snapshot.head.displayName,
                changedFileCount: snapshot.changes.count,
                lineCounts: counts,
                hasConflicts: !snapshot.conflicts.isEmpty,
                upstream: snapshot.upstream,
                lastFetchAt: snapshot.lastFetchAt
            ))

        } catch {
            return .projectFailure
        }

    }

    private static func readRequests(_ account: GitHubAccount, kind: RequestKind, gitHub: GitHubServiceProtocol) async -> RefreshResult {

        do {
            return .requests(kind, try await kind.load(for: account, from: gitHub))
        } catch {
            return .requestFailure(kind)
        }

    }

    private func mockChange(for project: RepositoryProject) -> OverviewProjectChange? {

        let files = project.files.filter { $0.status != .identical }
        guard !files.isEmpty else { return nil }

        let additions = files.reduce(0) { $0 + $1.additions + $1.changedLines }
        let deletions = files.reduce(0) { $0 + $1.deletions + $1.changedLines }

        return OverviewProjectChange(
            project: project,
            branchName: project.branch,
            changedFileCount: files.count,
            lineCounts: DiffLineCounts(additions: additions, deletions: deletions),
            hasConflicts: files.contains { $0.status == .conflicted }
        )

    }

}

private enum RequestKind: Equatable, Sendable {
    case assigned
    case reviewRequested

    func load(for account: GitHubAccount, from service: GitHubServiceProtocol) async throws -> AssignedPullRequestListing {

        switch self {

        case .assigned: try await service.assignedPullRequests(for: account)
        case .reviewRequested: try await service.reviewRequestedPullRequests(for: account)

        }

    }
}

private enum RefreshResult: Sendable {
    case project(OverviewProjectChange?)
    case projectFailure
    case requests(RequestKind, AssignedPullRequestListing)
    case requestFailure(RequestKind)
}
