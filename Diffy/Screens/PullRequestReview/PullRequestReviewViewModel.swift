import Foundation
import Combine

@MainActor
final class PullRequestReviewViewModel: ViewModel, Identifiable {

    let id = UUID()
    let loggerName = "PULL_REQUEST_REVIEW_VIEW_MODEL"
    let request: PullRequestReviewRequest
    let accounts: [GitHubAccount]
    let gitHub: GitHubServiceProtocol
    let fileNavigator = FileNavigatorViewModel(preferencesService: PreferencesService(defaults: nil))
    private var navigationObservation: AnyCancellable?
    private var navigatorDragStartWidth: CGFloat?

    @Published private(set) var navigatorWidth: CGFloat = 260
    @Published var selectedAccountID: String
    @Published private(set) var details: PullRequestReviewDetails?
    @Published var conversation: [PullRequestConversationEntry] = []
    @Published var selectedFileID: String?
    @Published private(set) var splitLines: [DiffLine] = []
    @Published private(set) var unifiedLines: [DiffLine] = []
    @Published var viewedPaths: Set<String> = []
    @Published var showsConversation = false
    @Published var showsReviewComposer = false
    @Published var showsDiscardConfirmation = false
    @Published var showsReloadConfirmation = false
    @Published var isUnified = true
    @Published var commentEditor: PullRequestReviewCommentDraft?
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
        gitHub: GitHubServiceProtocol
    ) {

        self.request = request
        self.accounts = accounts.filter { $0.host == request.link.host && $0.status == .connected }
        self.gitHub = gitHub
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

    var lines: [DiffLine] { self.isUnified ? self.unifiedLines : self.splitLines }
    var account: GitHubAccount? { self.accounts.first { $0.id == self.selectedAccountID } }
    var isBusy: Bool { self.isLoading || self.isSubmitting }
    var selectedFile: PullRequestReviewFile? { self.details?.files.first { $0.id == self.selectedFileID } }
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
            self.conversation = details.conversation
            self.isStale = false
            selectFile(details.files.first { $0.id == self.selectedFileID } ?? details.files.first)

        } catch is CancellationError {
            return
        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func changeAccount() async {

        self.details = nil
        self.conversation = []
        self.viewedPaths = []
        self.splitLines = []
        self.unifiedLines = []
        self.notice = nil
        await load()

    }

    func selectFile(_ file: PullRequestReviewFile?) {

        self.selectedFileID = file?.id
        self.splitLines = file?.patch.map(GitPatchParser.lines) ?? []
        self.unifiedLines = file?.patch.map(GitPatchParser.unifiedLines) ?? []

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
        } catch {
            self.errorMessage = "Your submission succeeded, but the conversation could not refresh. \(error.localizedDescription)"
        }

    }

}
