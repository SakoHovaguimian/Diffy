import Foundation
import Combine

@MainActor
final class RepositoryViewModel: ViewModel {

    let loggerName = "REPOSITORY_VIEW_MODEL"
    let runtime: AppRuntime
    let git: GitServiceProtocol
    let gitHub: GitHubServiceProtocol
    let accounts: GitHubAccountServiceProtocol
    let comparison: RepositoryComparisonViewModel
    let reviewDiffBuilder: TextDiffBuilding
    private var refreshID = UUID()
    var pathInventoryRequestID = UUID()
    var historyRequestID = UUID()
    var commitsRequestID = UUID()
    var pullRequestsRequestID = UUID()
    var patchTask: Task<Void, Never>?
    private var operationTask: Task<Void, Never>?
    private var drafts: [String: String] = [:]

    @Published private(set) var project: RepositoryProject?
    @Published private(set) var snapshot: GitRepositorySnapshot?
    @Published private(set) var unstagedLineCounts: DiffLineCounts?
    @Published private(set) var isRefreshing = false
    @Published private(set) var isOperating = false
    @Published private(set) var operationTitle = ""
    @Published var errorMessage: String?
    @Published private(set) var notice: String?
    @Published var pendingAction: GitActionConfirmation?
    @Published var commitMessage = ""
    @Published var newBranchName = ""
    @Published var selectedRemote = ""
    @Published var showsAddRemote = false
    @Published var newRemoteName = "origin"
    @Published var newRemoteURL = ""
    @Published var pullStrategy: GitPullStrategy = .fastForwardOnly
    @Published var branchBase = ""
    @Published var branchTarget = ""
    @Published var search = ""
    @Published var visibleLimit = 50
    @Published var showsCommitComposer = false
    @Published var comparisonReview: ComparisonReviewRequest?
    @Published var showsPatch = false
    @Published var patchText = ""
    @Published var patchTitle = ""
    @Published var patchError: String?
    @Published var isLoadingPatch = false
    @Published var isLoadingBranchReview = false
    @Published var selectedPath: String?
    @Published var selectedCommit: RepositoryCommit?
    @Published var trackedPaths: [String] = []
    @Published var pathEntries: [RepositoryPathEntry] = []
    @Published var historyLayout: RepositoryFileLayout = .flat
    @Published var historySort: RepositoryFileSort = .name
    @Published var historyExpandedFolders: Set<String> = []
    @Published var historyBranch = ""
    @Published var isLoadingHistoryFiles = false
    @Published var historyFilesError: String?
    @Published var folderEntries: [RepositoryPathEntry] = []
    @Published var folderLayout: RepositoryFileLayout = .tree
    @Published var folderSort: RepositoryFileSort = .name
    @Published var folderExpandedFolders: Set<String> = []
    @Published var selectedFolderPath: String?
    @Published var history: [RepositoryCommit] = []
    @Published var historyPath = ""
    @Published var historyLimit = 50
    @Published var isLoadingHistory = false
    @Published var commitsBranch = ""
    @Published var branchCommits: [RepositoryCommit] = []
    @Published var isLoadingCommits = false
    @Published var commitsError: String?
    @Published var gitHubReview: PullRequestReviewViewModel?
    @Published var pullRequests: [PullRequestSummary] = []
    @Published var pullRequestFilter: PullRequestFilter = .all
    @Published var pullRequestStatusFilter: PullRequestStatusFilter = .unmerged
    @Published var pullRequestCheckFilter: PullRequestCheckFilter = .any
    @Published var selectedAccountID = ""
    @Published var isLoadingPullRequests = false
    @Published var isLoadingChecks = false
    @Published var pullRequestError: String?
    @Published var leftFolder: URL?
    @Published var rightFolder: URL?
    @Published var currentMode: ComparisonMode = .workingTree

    init(
        runtime: AppRuntime,
        git: GitServiceProtocol,
        gitHub: GitHubServiceProtocol,
        accounts: GitHubAccountServiceProtocol,
        diffBuilder: TextDiffBuilding
    ) {

        self.runtime = runtime
        self.git = git
        self.gitHub = gitHub
        self.accounts = accounts
        self.reviewDiffBuilder = diffBuilder
        self.comparison = RepositoryComparisonViewModel(git: git)

    }

    var reference: GitRepositoryReference? {

        guard let project = self.project else { return nil }
        return project.repositoryReference ?? (self.runtime.isLive ? nil : GitRepositoryReference(projectID: project.id, checkout: LocalCheckoutReference(bookmarkData: nil, lastKnownPath: "/preview/\(project.name)")))

    }

    var canMutate: Bool {
        self.runtime.isLive && self.snapshot != nil && !self.isOperating && !self.isRefreshing
    }

    var linkedRepository: GitHubRepositoryLink? {

        if let link = self.project?.gitHubLink { return link }
        guard let remote = self.snapshot?.gitHubRemote, let coordinate = remote.gitHubCoordinate else { return nil }
        return GitHubRepositoryLink(coordinate: coordinate, remoteName: remote.name)

    }

    var availableAccounts: [GitHubAccount] {
        self.accounts.loadAccounts().filter { $0.host == self.linkedRepository?.host }
    }

    var visiblePullRequests: [PullRequestSummary] {

        let login = self.availableAccounts.first { $0.id == self.selectedAccountID }?.login ?? ""
        return self.pullRequests.filter {
            self.pullRequestFilter.matches($0, viewerLogin: login)
                && self.pullRequestStatusFilter.matches($0)
                && self.pullRequestCheckFilter.matches($0)
        }

    }

    var visibleChanges: [GitFileChange] {

        let changes = self.currentMode == .staged ? self.snapshot?.stagedChanges : self.snapshot?.changes.filter { $0.hasUnstagedChanges || $0.isConflicted }
        return (changes ?? []).filter { self.search.isEmpty || $0.path.localizedStandardContains(self.search) }

    }

    var visiblePaths: [String] {
        self.trackedPaths.filter { self.search.isEmpty || $0.localizedStandardContains(self.search) }
    }

    func updateProjectPresentation(_ project: RepositoryProject) {

        guard self.project?.id == project.id else { return }

        self.project?.displayName = project.displayName
        self.project?.symbol = project.symbol

    }

    func load(_ project: RepositoryProject) async {

        guard !self.isOperating else { return }
        if let previous = self.project { self.drafts[previous.id] = self.commitMessage }
        self.patchTask?.cancel()
        self.comparison.reset()
        self.showsPatch = false
        self.comparisonReview = nil
        self.refreshID = UUID()
        self.project = project
        self.snapshot = nil
        self.unstagedLineCounts = nil
        self.commitMessage = self.drafts[project.id] ?? ""
        self.search = ""
        self.visibleLimit = 50
        self.selectedPath = nil
        self.selectedCommit = nil
        self.patchText = ""
        self.patchError = nil
        self.patchTitle = ""
        self.history = []
        self.branchCommits = []
        self.pathInventoryRequestID = UUID()
        self.historyRequestID = UUID()
        self.commitsRequestID = UUID()
        self.pullRequestsRequestID = UUID()
        self.isLoadingHistory = false
        self.isLoadingHistoryFiles = false
        self.isLoadingCommits = false
        self.isLoadingPullRequests = false
        self.isLoadingChecks = false
        self.isLoadingPatch = false
        self.isLoadingBranchReview = false
        self.historyPath = ""
        self.historyBranch = ""
        self.historyFilesError = nil
        self.commitsBranch = ""
        self.commitsError = nil
        self.pullRequests = []
        self.trackedPaths = []
        self.pathEntries = []
        self.folderEntries = []
        self.historyExpandedFolders = []
        self.historyLayout = .flat
        self.folderExpandedFolders = []
        self.selectedFolderPath = nil
        self.leftFolder = nil
        self.rightFolder = nil
        self.notice = nil
        await refresh()

    }

    func refresh() async {

        guard let reference, !self.isOperating else { return }
        let request = UUID()
        self.refreshID = request
        self.isRefreshing = true
        self.errorMessage = nil
        defer { if self.refreshID == request { self.isRefreshing = false } }

        do {

            let snapshot = try await self.git.snapshot(of: reference, scope: .full, previous: self.snapshot)
            try Task.checkCancellation()
            guard self.refreshID == request else { return }
            self.snapshot = snapshot
            self.unstagedLineCounts = snapshot.unstagedChanges.isEmpty ? DiffLineCounts(additions: 0, deletions: 0) : nil
            if !snapshot.unstagedChanges.isEmpty, snapshot.unstagedChanges.filter(\.isUntracked).count <= 100 {
                Task { [git] in
                    let patch = try? await git.patch(in: reference, selection: .workingTree)
                    guard self.reference == reference, self.refreshID == request else { return }
                    self.unstagedLineCounts = patch.flatMap { $0.contains("Binary files ") ? nil : GitPatchParser.lineCounts($0) }
                }
            }
            self.selectedRemote = snapshot.remotes.contains { $0.name == self.selectedRemote } ? self.selectedRemote : snapshot.remotes.first?.name ?? ""
            self.branchBase = snapshot.localBranches.contains { $0.name == self.branchBase } ? self.branchBase : snapshot.localBranches.first(where: { !$0.isCurrent })?.name ?? snapshot.head.branchName ?? ""
            self.branchTarget = snapshot.head.branchName ?? "HEAD"
            let defaultBranch = snapshot.head.branchName ?? (snapshot.head.commitID == nil ? "" : "HEAD")
            let branchNames = Set(snapshot.branches.map(\.name))
            self.historyBranch = branchNames.contains(self.historyBranch) ? self.historyBranch : defaultBranch
            self.commitsBranch = branchNames.contains(self.commitsBranch) ? self.commitsBranch : defaultBranch
            if self.commitsBranch == defaultBranch {
                self.branchCommits = snapshot.recentCommits
            }
            self.selectedAccountID = self.availableAccounts.contains { $0.id == self.selectedAccountID } ? self.selectedAccountID : self.project?.gitHubAccountID ?? self.availableAccounts.first?.id ?? ""

            if !self.showsPatch, self.comparisonReview == nil, [.workingTree, .staged].contains(self.currentMode) {
                inspectChanges(path: nil)
            }

        } catch is CancellationError {
            return
        } catch {

            guard self.refreshID == request else { return }
            self.errorMessage = error.localizedDescription

        }

    }

    func activate(_ mode: ComparisonMode) {

        self.currentMode = mode
        self.search = ""
        self.visibleLimit = 50
        self.patchTask?.cancel()
        self.showsPatch = false

        if ![.workingTree, .staged].contains(mode) {
            self.comparison.reset()
        }

        self.patchText = ""
        self.patchTitle = ""
        self.patchError = nil
        self.isLoadingPatch = false
        self.selectedPath = nil

        switch mode {

        case .workingTree, .staged:
            inspectChanges(path: nil)

        case .history:
            self.historyLayout = .flat
            self.historyExpandedFolders = []
            Task { await loadPaths() }

        case .commits:
            Task { await loadCommits() }

        case .pullRequests:
            Task { await loadPullRequests() }

        default:
            break

        }

    }

    func inspectChanges(path: String?) {

        if let path, let file = self.comparison.files.first(where: { $0.path == path }) {

            self.comparison.select(file)
            return

        }

        let selection = self.currentMode == .staged ? ComparisonSelection.staged : .workingTree
        inspect(selection, title: selection.title)

    }

    func inspectCommit(_ commit: RepositoryCommit) {

        self.selectedCommit = commit
        showComparisonReview(
            .commit(commit.id),
            title: "\(commit.shortID) · \(commit.title)",
            mode: self.currentMode == .history ? .history : .commits
        )

    }

    func selectHistoryBranch(_ branch: String) {

        guard self.historyBranch != branch else { return }
        self.historyBranch = branch
        self.historyExpandedFolders = []
        self.pathEntries = []
        self.trackedPaths = []
        self.history = []
        self.isLoadingHistory = !self.historyPath.isEmpty
        self.isLoadingHistoryFiles = true
        self.historyFilesError = nil
        self.patchError = nil
        Task { await loadPaths() }

    }

    func selectCommitsBranch(_ branch: String) {

        guard self.commitsBranch != branch else { return }
        self.commitsBranch = branch
        self.branchCommits = []
        self.commitsError = nil
        Task { await loadCommits() }

    }

    func browsingRevision(for branch: String) -> String? {

        guard !branch.isEmpty else { return nil }

        if branch == self.snapshot?.head.branchName
            || (branch == "HEAD" && self.snapshot?.head.isDetached == true) {
            return nil
        }

        return branch

    }

    func compareBranches() {

        let selection = ComparisonSelection(left: .revision(self.branchBase), right: .revision(self.branchTarget), usesMergeBase: true)
        showComparisonReview(selection, title: "Compare branches", detail: "\(self.branchTarget) relative to merge base with \(self.branchBase)", mode: .branches, startsExpanded: false)

    }

    func inspect(_ selection: ComparisonSelection, title: String) {

        guard let reference else { return }
        let isWorkingComparison = selection == .workingTree || selection == .staged

        if isWorkingComparison {

            self.patchTask?.cancel()
            self.patchTitle = title
            self.comparison.load(in: reference, selection: selection)

        } else {
            showComparisonReview(selection, title: title, mode: self.currentMode)
        }

    }

    func request(_ action: GitOperationRequest) {

        guard self.canMutate else { return }
        let consequence: String?

        switch action {

        case let .startRebase(onto): consequence = "Replay this branch's commits onto \(onto). Commit IDs will change. Keep local changes committed before continuing."
        case let .startMerge(branch): consequence = "Merge \(branch) into the current branch. Git may create a merge commit or pause for conflicts."
        case let .restore(paths): consequence = "Discard unstaged edits in \(paths.count) selected file(s). The index is preserved. Discarded edits cannot be recovered by Diffy."
        case let .push(options) where options.forceWithLease: consequence = "Replace the remote branch with this branch, only if the remote still matches your last fetch. This rewrites published history."
        case .abortMerge, .abortRebase: consequence = "Abort the current operation and return to its starting state. Conflict-resolution edits may be lost."
        case let .resolveConflict(path, choice, _): consequence = "Replace all of \(path) with \(choice == .yours ? "your" : "incoming") contents and stage it. Any edits in the working file will be replaced."
        default: consequence = nil

        }

        if let consequence {
            self.pendingAction = GitActionConfirmation(request: action, projectName: self.project?.displayName ?? "", consequence: consequence)
        } else {
            perform(action)
        }

    }

    func confirmAction() {

        guard let pending = self.pendingAction else { return }
        self.pendingAction = nil
        perform(pending.request)

    }

    private func perform(_ action: GitOperationRequest) {

        guard let reference, self.canMutate else { return }
        self.isOperating = true
        self.operationTitle = action.title
        self.errorMessage = nil
        self.notice = nil
        self.operationTask = Task {

            var operationComparison: GitOperationComparison?

            do {

                let result = try await self.git.perform(action, in: reference) { _ in }
                self.notice = result.message
                operationComparison = result.comparison

                if case .commit = action {
                    self.commitMessage = ""
                    self.showsCommitComposer = false
                }

            } catch is CancellationError {
                self.notice = "Operation stopped. Refreshing Git's state; completed changes are preserved."
            } catch {
                self.notice = nil
                self.errorMessage = error.localizedDescription
            }

            let operationError = self.errorMessage
            self.isOperating = false
            await Task { await self.refresh() }.value
            self.errorMessage = operationError ?? self.errorMessage

            if let operationComparison, self.reference == reference {
                showOperationReview(operationComparison, in: reference)
            }

        }

    }

    func inspectPullRequest(_ pullRequest: PullRequestSummary) {

        guard let reference, let remote = self.linkedRepository?.remoteName, self.canMutate else { return }
        self.isOperating = true
        self.operationTitle = "Fetch pull request #\(pullRequest.number)"
        self.pullRequestError = nil
        self.operationTask = Task {

            do {

                let selection = try await self.git.fetchPullRequestSources(pullRequest, remoteName: remote, in: reference) { _ in }
                self.isOperating = false
                inspect(selection, title: "#\(pullRequest.number) · \(pullRequest.title)")

            } catch is CancellationError {
                self.notice = "Pull request fetch stopped. Completed objects are preserved."
            } catch {
                self.pullRequestError = error.localizedDescription
            }

            self.isOperating = false
            await Task { await self.refresh() }.value

        }

    }

    func cancelOperation() {
        self.operationTask?.cancel()
    }

    func continueOperation() {

        if case .rebasing = self.snapshot?.operation {
            request(.continueRebase)
        } else {
            request(.continueMerge)
        }

    }

    func abortOperation() {

        if case .rebasing = self.snapshot?.operation {
            request(.abortRebase)
        } else {
            request(.abortMerge)
        }

    }

}
