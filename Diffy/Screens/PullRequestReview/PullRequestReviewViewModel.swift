import Foundation
import Combine

@MainActor
final class PullRequestReviewViewModel: ViewModel, Identifiable {

    let id = UUID()
    let loggerName = "PULL_REQUEST_REVIEW_VIEW_MODEL"
    let request: PullRequestReviewRequest
    @Published private(set) var localRepository: GitRepositoryReference?
    @Published private(set) var projectID: String?
    var patchReview: AIReviewPatchViewModel?
    let accounts: [GitHubAccount]
    let gitHub: GitHubServiceProtocol
    let textDiff: TextDiffViewModel
    let fileNavigator = FileNavigatorViewModel(preferencesService: PreferencesService(defaults: nil))
    private var navigationObservation: AnyCancellable?
    private var navigatorDragStartWidth: CGFloat?

    @Published private(set) var navigatorWidth: CGFloat = 260
    @Published var selectedAccountID: String
    @Published private(set) var details: PullRequestReviewDetails?
    @Published private(set) var aiWorkspace: AIReviewWorkspaceViewModel?
    @Published var conversation: [PullRequestConversationEntry] = []
    @Published var selectedFileID: String?
    @Published private(set) var historicalFileSelection: PullRequestHistoricalFileSelection?
    @Published private(set) var splitLines: [DiffLine] = []
    @Published var viewedPaths: Set<String> = []
    @Published var selectedTab: PullRequestReviewTab = .filesChanged
    @Published var showsNotes = false
    @Published var showsReviewComposer = false
    @Published var showsReloadConfirmation = false
    @Published var isUnified = true
    @Published var commentEditor: PullRequestReviewCommentDraft?
    @Published var noteDraft: PullRequestNoteDraft?
    @Published var drafts: [PullRequestReviewCommentDraft] = []
    @Published var reviewBody = ""
    @Published var reviewEvent: PullRequestReviewEvent = .comment
    @Published var conversationBody = ""
    @Published var replyingTo: PullRequestConversationEntry?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var isStale = false
    @Published var errorMessage: String?
    @Published var notice: String?

    init(
        request: PullRequestReviewRequest,
        accounts: [GitHubAccount],
        gitHub: GitHubServiceProtocol,
        diffBuilder: TextDiffBuilding,
        localRepository: GitRepositoryReference? = nil,
        projectID: String? = nil
    ) {

        self.request = request
        self.localRepository = localRepository
        self.projectID = projectID
        self.accounts = accounts.filter { $0.host == request.link.host && $0.status == .connected }
        self.gitHub = gitHub
        self.textDiff = TextDiffViewModel(diffBuilder: diffBuilder)
        self.selectedAccountID = self.accounts.first { $0.id == request.preferredAccountID }?.id ?? self.accounts.first?.id ?? ""
        self.navigationObservation = self.fileNavigator.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

    }

    func resizeNavigator(by translation: CGFloat, maximumWidth: CGFloat) {

        if self.navigatorDragStartWidth == nil {
            self.navigatorDragStartWidth = min(self.navigatorWidth, maximumWidth)
        }

        let startingWidth = self.navigatorDragStartWidth ?? self.navigatorWidth
        self.navigatorWidth = min(maximumWidth, max(190, startingWidth + translation))

    }

    func finishResizingNavigator() {
        self.navigatorDragStartWidth = nil
    }

    var lines: [DiffLine] { self.splitLines }
    var account: GitHubAccount? { self.accounts.first { $0.id == self.selectedAccountID } }
    var isBusy: Bool { self.isLoading || self.isSubmitting }
    var selectedFile: PullRequestReviewFile? { self.details?.files.first { $0.id == self.selectedFileID } }
    var selectedComparisonFile: DiffFile? {
        self.selectedFile?.navigationFile.replacingContent(lines: self.splitLines, kind: .text)
    }
    var hasDrafts: Bool { !self.drafts.isEmpty || !self.reviewBody.isEmpty || !self.conversationBody.isEmpty || self.commentEditor != nil }

    var navigationFiles: [DiffFile] {
        self.details?.files.map(\.navigationFile) ?? []
    }

    var visibleFiles: [PullRequestReviewFile] {

        let filesByID = Dictionary(uniqueKeysWithValues: (self.details?.files ?? []).map { ($0.id, $0) })
        return self.fileNavigator.visibleFiles(self.navigationFiles, mode: .pullRequests).compactMap { filesByID[$0.id] }

    }

    func canMoveFile(by offset: Int) -> Bool {

        let files = self.visibleFiles
        guard let index = files.firstIndex(where: { $0.id == self.selectedFileID }) else { return false }
        return files.indices.contains(index + offset)

    }

    var selectedFileComments: [PullRequestConversationEntry] {
        self.conversation.filter { $0.kind == .inline && $0.path == self.selectedFileID }
    }

    var canReview: Bool {
        self.details?.summary.lifecycle == .open && self.account != nil && !self.isBusy && !self.isStale && !self.hasPendingRemoteReview
    }

    var hasPendingRemoteReview: Bool {
        self.conversation.contains { $0.isPending && $0.author.caseInsensitiveCompare(self.account?.login ?? "") == .orderedSame }
    }

    var canDecide: Bool {

        guard let summary = self.details?.summary, let account else { return false }
        return !summary.isDraft && !summary.isAuthored(by: account.login)

    }

    var canSubmit: Bool {

        guard self.canReview, self.reviewEvent == .comment || self.canDecide else { return false }
        return self.reviewEvent == .approve || !self.reviewBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    }

    func drafts(at line: DiffLine) -> [PullRequestReviewCommentDraft] {
        self.drafts.filter { $0.path == self.selectedFileID && $0.line == ($0.side == "LEFT" ? line.oldNumber : line.newNumber) }
    }

    func comments(at line: DiffLine) -> [PullRequestConversationEntry] {
        self.selectedFileComments.filter { $0.line != nil && $0.line == ($0.side == "LEFT" ? line.oldNumber : line.newNumber) }
    }

    var unanchoredFileComments: [PullRequestConversationEntry] {

        self.selectedFileComments.filter { comment in
            !self.lines.contains { line in
                comment.line != nil && comment.line == (comment.side == "LEFT" ? line.oldNumber : line.newNumber)
            }
        }

    }

    var discussionLineIDs: Set<Int> {
        Set(self.lines.filter { !self.drafts(at: $0).isEmpty || !self.comments(at: $0).isEmpty }.map(\.id))
    }

    // MARK: - Loading

    func load() async {

        guard !self.isBusy, !self.hasDrafts else { return }
        guard let account else {

            self.errorMessage = "Connect a GitHub account for this repository in Settings → Accounts."
            return

        }

        self.isLoading = true
        self.errorMessage = nil
        defer { self.isLoading = false }

        do {

            let details = try await self.gitHub.reviewDetails(for: self.request, account: account)
            try Task.checkCancellation()
            let revisionChanged = self.details?.summary.headSHA != details.summary.headSHA || self.details?.summary.baseSHA != details.summary.baseSHA
            if revisionChanged { self.viewedPaths.removeAll() }
            self.details = details
            self.aiWorkspace?.update(details: details)
            self.conversation = details.conversation
            self.isStale = false
            selectFile(details.files.first { $0.id == self.selectedFileID } ?? details.files.first)

        } catch is CancellationError {
            return
        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func loadIfNeeded() async {
        if self.details == nil { await load() }
    }

    func attachAIWorkspace(_ aiWorkspace: AIReviewWorkspaceViewModel) {

        guard self.aiWorkspace == nil else { return }
        self.aiWorkspace = aiWorkspace
        if let details = self.details { aiWorkspace.update(details: details) }

    }

    func attachLocalRepository(_ repository: GitRepositoryReference?, projectID: String?) {

        guard let repository, self.localRepository != repository else { return }
        self.localRepository = repository
        self.projectID = projectID
        self.patchReview?.attachRepository(repository)

    }

    func changeAccount() async {

        self.details = nil
        self.aiWorkspace?.clearCurrentDetails()
        self.conversation = []
        self.viewedPaths = []
        self.splitLines = []
        self.notice = nil
        await load()

    }

    func selectFile(_ file: PullRequestReviewFile?) {

        self.selectedFileID = file?.id
        self.splitLines = file?.patch.map(GitPatchParser.lines) ?? []

    }

    func openFile(path: String) {

        guard let file = self.details?.files.first(where: { $0.filename == path || $0.previousFilename == path }) else {
            self.notice = "The file is unavailable in this pull request revision."
            return
        }

        self.fileNavigator.query = ""
        self.fileNavigator.collapsedGroups = []
        self.historicalFileSelection = nil
        selectFile(file)
        self.selectedTab = .filesChanged

    }

    func openAnalyzedFile(generation: AIReviewGeneration, path: String) {

        let isCurrentRevision = self.details.map {
            generation.isCurrent(baseSHA: $0.summary.baseSHA, headSHA: $0.summary.headSHA)
        } ?? false
        if isCurrentRevision,
           let currentFile = self.details?.files.first(where: { $0.filename == path || $0.previousFilename == path }) {

            let currentPatchIsComplete: Bool
            if let patch = currentFile.patch {
                let counts = GitPatchParser.lineCounts(patch)
                currentPatchIsComplete = counts.additions == currentFile.additions
                    && counts.deletions == currentFile.deletions
            } else {
                currentPatchIsComplete = false
            }
            if generation.visualizationType != .riskMap || currentPatchIsComplete {
                openFile(path: path)
                return
            }

        }

        guard let file = (generation.analyzedFiles + generation.context.files)
            .first(where: { $0.filename == path || $0.previousFilename == path }) else {
            self.notice = "This analysis did not capture a patch for \(path). The original explanation remains in history."
            return
        }

        self.historicalFileSelection = PullRequestHistoricalFileSelection(
            file: file,
            createdAt: generation.createdAt,
            headSHA: generation.headSHA,
            isCurrentRevision: isCurrentRevision
        )
        self.selectedTab = .filesChanged

    }

    func openNoteFixFile(entry: AIConversationEntry, path: String) {

        if let details = self.details,
           entry.baseSHA == details.summary.baseSHA,
           entry.headSHA == details.summary.headSHA,
           details.files.contains(where: { $0.filename == path || $0.previousFilename == path }) {
            openFile(path: path)
            return
        }

        guard let file = entry.analyzedFiles.first(where: { $0.filename == path || $0.previousFilename == path }) else {
            self.notice = "This analysis did not capture a patch for \(path). The original fix remains in history."
            return
        }

        self.historicalFileSelection = PullRequestHistoricalFileSelection(
            file: file,
            createdAt: entry.createdAt,
            headSHA: entry.headSHA,
            isCurrentRevision: false
        )
        self.selectedTab = .filesChanged

    }

    func closeHistoricalFile() {

        self.historicalFileSelection = nil

    }

    func moveFile(by offset: Int) {

        let files = self.visibleFiles
        guard let index = files.firstIndex(where: { $0.id == self.selectedFileID }), files.indices.contains(index + offset) else { return }
        selectFile(files[index + offset])

    }

    func beginComment(line: Int, side: String) {

        guard self.canReview, let file = self.selectedFile else { return }
        self.commentEditor = PullRequestReviewCommentDraft(path: file.filename, line: line, side: side, body: "")

    }

    func saveComment(_ draft: PullRequestReviewCommentDraft) {

        guard !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.drafts.removeAll { $0.id == draft.id }
        self.drafts.append(draft)
        self.commentEditor = nil

    }

    func discardDrafts() {

        self.drafts = []
        self.reviewBody = ""
        self.conversationBody = ""
        self.commentEditor = nil
        self.replyingTo = nil

    }

    // MARK: - Publishing

    func submitReview() async {

        guard self.canSubmit, let account, let details else { return }
        let submission = PullRequestReviewSubmission(commitID: details.summary.headSHA, body: self.reviewBody, event: self.reviewEvent, comments: self.drafts)
        self.isSubmitting = true
        self.errorMessage = nil
        self.notice = nil
        defer { self.isSubmitting = false }

        do {

            let current = try await self.gitHub.pullRequest(number: self.request.number, link: self.request.link, account: account)
            guard current.headSHA == details.summary.headSHA, current.baseSHA == details.summary.baseSHA, current.lifecycle == .open else {

                self.isStale = true
                self.errorMessage = "This pull request changed or closed. Your draft is preserved. Refresh and review the latest files before submitting."
                self.showsReviewComposer = false
                return

            }

            guard submission.event == .comment || (!current.isDraft && !current.isAuthored(by: account.login)) else {
                throw GitHubError.reviewUnavailable("Draft pull requests and your own pull requests can receive comments, but not an approval or change request from this account.")
            }

            try await self.gitHub.submitReview(submission, for: self.request, account: account)
            self.drafts = []
            self.reviewBody = ""
            self.showsReviewComposer = false
            self.notice = "Review submitted to GitHub as \(account.handle)."
            await refreshConversation(account: account)

        } catch {
            self.errorMessage = "\(error.localizedDescription) Your draft is preserved. Check GitHub before retrying if the connection was interrupted."
        }

    }

    func postConversationComment() async {

        guard !self.isBusy, let account, self.details != nil else { return }
        let body = self.conversationBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        let replyID = self.replyingTo.map { $0.replyToID ?? $0.remoteID }
        self.isSubmitting = true
        self.errorMessage = nil
        self.notice = nil
        defer { self.isSubmitting = false }

        do {

            try await self.gitHub.postPullRequestComment(body, replyingTo: replyID, for: self.request, account: account)
            self.conversationBody = ""
            self.replyingTo = nil
            self.notice = "Comment posted to GitHub as \(account.handle)."
            await refreshConversation(account: account)

        } catch {
            self.errorMessage = "\(error.localizedDescription) Your comment is preserved. Check GitHub before retrying if the connection was interrupted."
        }

    }

    private func refreshConversation(account: GitHubAccount) async {

        do {

            self.conversation = try await self.gitHub.reviewConversation(for: self.request, account: account)
            if let details = self.details {

                let updated = details.replacingConversation(self.conversation)
                self.details = updated
                self.aiWorkspace?.update(details: updated)

            }

        } catch {
            self.errorMessage = "Your submission succeeded, but the conversation could not refresh. \(error.localizedDescription)"
        }

    }

}
