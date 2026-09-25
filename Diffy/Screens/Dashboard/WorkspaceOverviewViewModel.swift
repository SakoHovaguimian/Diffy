import Foundation
import Combine

@MainActor
final class WorkspaceOverviewViewModel: ViewModel {

    let loggerName = "WORKSPACE_OVERVIEW_VIEW_MODEL"
    private let runtime: AppRuntime
    private let git: GitServiceProtocol
    private let gitHub: GitHubServiceProtocol
    private var refreshID = UUID()

    @Published private(set) var activeProjects: [OverviewProjectChange] = []
    @Published private(set) var assignedPullRequests: [AssignedPullRequestSummary] = []
    @Published private(set) var hasMoreAssignedPullRequests = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var projectError: String?
    @Published private(set) var pullRequestError: String?

    init(
        runtime: AppRuntime,
        git: GitServiceProtocol,
        gitHub: GitHubServiceProtocol
    ) {

        self.runtime = runtime
        self.git = git
        self.gitHub = gitHub

    }

    func refresh(projects: [RepositoryProject], accounts: [GitHubAccount]) async {

        let requestID = UUID()
        self.refreshID = requestID
        self.isRefreshing = true
        self.hasLoaded = false
        self.activeProjects = []
        self.assignedPullRequests = []
        self.hasMoreAssignedPullRequests = false
        self.projectError = nil
        self.pullRequestError = nil
        defer { if self.refreshID == requestID { self.isRefreshing = false } }

        var changes: [OverviewProjectChange] = []
        var failedProjects = 0

        for project in projects {

            guard !Task.isCancelled, self.refreshID == requestID else { return }

            if !self.runtime.isLive {

                if let change = mockChange(for: project) {
                    changes.append(change)
                }

                continue

            }

            guard let reference = project.repositoryReference else { continue }

            do {

                let snapshot = try await self.git.snapshot(of: reference, scope: .status, previous: nil)

                if !snapshot.isClean {
                    let counts = try? await lineCounts(in: reference)
                    changes.append(OverviewProjectChange(
                        project: project,
                        branchName: snapshot.head.displayName,
                        changedFileCount: snapshot.changes.count,
                        lineCounts: counts,
                        hasConflicts: !snapshot.conflicts.isEmpty
                    ))
                }

            } catch is CancellationError {
                return
            } catch {
                failedProjects += 1
            }

        }

        guard !Task.isCancelled, self.refreshID == requestID else { return }
        self.activeProjects = changes.sorted { $0.project.displayName.localizedStandardCompare($1.project.displayName) == .orderedAscending }

        if failedProjects > 0 {
            self.projectError = "Couldn’t read \(failedProjects) project\(failedProjects == 1 ? "" : "s"). Check the folder and refresh."
        }

        await loadAssignedPullRequests(accounts: accounts, requestID: requestID)

        guard !Task.isCancelled, self.refreshID == requestID else { return }
        self.hasLoaded = true

    }

    private func lineCounts(in reference: GitRepositoryReference) async throws -> DiffLineCounts {

        let workingPatch = try await self.git.patch(in: reference, selection: .workingTree)
        let stagedPatch = try await self.git.patch(in: reference, selection: .staged)
        let working = GitPatchParser.lineCounts(workingPatch)
        let staged = GitPatchParser.lineCounts(stagedPatch)

        return DiffLineCounts(
            additions: working.additions + staged.additions,
            deletions: working.deletions + staged.deletions
        )

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

    private func loadAssignedPullRequests(
        accounts: [GitHubAccount],
        requestID: UUID
    ) async {

        var requests: [AssignedPullRequestSummary] = []
        var seenRequestIDs: Set<String> = []
        var failedAccounts = 0
        var hasMore = false

        for account in accounts where account.status == .connected {

            guard !Task.isCancelled, self.refreshID == requestID else { return }

            do {

                let listing = try await self.gitHub.assignedPullRequests(for: account)
                hasMore = hasMore || listing.hasMore

                for request in listing.requests {

                    if seenRequestIDs.insert(request.id).inserted {
                        requests.append(request)
                    }

                }

            } catch is CancellationError {
                return
            } catch {
                failedAccounts += 1
            }

        }

        guard !Task.isCancelled, self.refreshID == requestID else { return }
        self.assignedPullRequests = requests.sorted { $0.updatedAt > $1.updatedAt }
        self.hasMoreAssignedPullRequests = hasMore

        if failedAccounts > 0 {
            self.pullRequestError = "Couldn’t load pull requests for \(failedAccounts) account\(failedAccounts == 1 ? "" : "s"). Refresh to retry."
        }

    }

}
