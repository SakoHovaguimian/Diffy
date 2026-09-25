import Foundation
import Combine

@MainActor
final class AIReviewPatchViewModel: ViewModel {

    let loggerName = "AI_REVIEW_PATCH_VIEW_MODEL"
    private var repository: GitRepositoryReference?
    private let git: any GitServiceProtocol
    private let request: PullRequestReviewRequest
    private let latestPullRequest: @MainActor () async throws -> PullRequestSummary
    private var appliedEntryIDs = Set<UUID>()

    @Published private(set) var isApplying = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var notice: String?
    @Published private(set) var latestSnapshot: GitRepositorySnapshot?

    init(
        repository: GitRepositoryReference?,
        git: any GitServiceProtocol,
        request: PullRequestReviewRequest,
        latestPullRequest: @escaping @MainActor () async throws -> PullRequestSummary
    ) {

        self.repository = repository
        self.git = git
        self.request = request
        self.latestPullRequest = latestPullRequest

    }

    func canApply(entry: AIConversationEntry, current: PullRequestReviewDetails?) -> Bool {
        self.unavailableReason(entry: entry, current: current) == nil
    }

    func attachRepository(_ repository: GitRepositoryReference) {

        guard self.repository != repository, !self.isApplying else { return }
        self.repository = repository
        self.errorMessage = nil
        self.notice = nil
        self.latestSnapshot = nil

    }

    func unavailableReason(entry: AIConversationEntry, current: PullRequestReviewDetails?) -> String? {

        guard self.repository != nil else {
            return "Link a local checkout for this repository to apply a reviewed proposal."
        }

        guard !self.isApplying else { return "Applying the reviewed patch…" }
        guard !self.appliedEntryIDs.contains(entry.id) else { return "This proposal was already applied in this workspace." }
        guard let current else { return "Refresh the PR before applying a saved proposal." }
        let identity = "\(self.request.link.host)/\(self.request.link.fullName)".lowercased()

        guard entry.repositoryIdentity.lowercased() == identity,
              entry.pullRequestNumber == self.request.number,
              entry.baseSHA == current.summary.baseSHA,
              entry.headSHA == current.summary.headSHA else {
            return "This proposal belongs to an older PR revision. Generate a new proposal before applying."
        }

        guard case .noteFix(let fix) = entry.output, !fix.proposedPatch.isEmpty else {
            return "This response has no patch to apply."
        }

        return nil

    }

    // MARK: - Explicit Apply

    func apply(entry: AIConversationEntry, current: PullRequestReviewDetails?) async {

        if let reason = self.unavailableReason(entry: entry, current: current) {

            self.errorMessage = reason
            return

        }

        guard let repository, case .noteFix(let fix) = entry.output else { return }
        self.isApplying = true
        self.errorMessage = nil
        self.notice = nil
        defer { self.isApplying = false }

        do {

            let latest = try await self.latestPullRequest()

            guard latest.baseSHA == entry.baseSHA, latest.headSHA == entry.headSHA else {
                throw AIReviewError.unavailable("The PR changed after this proposal was generated. Refresh the PR and generate a fix for its latest revision.")
            }

            let capturedPaths = Set(entry.analyzedFiles.map(\.filename))

            guard !fix.affectedFiles.isEmpty,
                  Set(fix.affectedFiles).count == fix.affectedFiles.count,
                  Set(fix.affectedFiles).isSubset(of: capturedPaths) else {
                throw AIReviewError.invalidResponse("The proposal includes files outside its captured review context.")
            }

            let request = GitAIPatchRequest(
                patch: fix.proposedPatch,
                allowedPaths: fix.affectedFiles,
                expectedHeadSHA: entry.headSHA
            )
            try await self.git.applyReviewedAIPatch(request, in: repository)
            self.appliedEntryIDs.insert(entry.id)
            self.notice = "Applied the reviewed patch to \(fix.affectedFiles.count) working-tree files. Review the local diff before staging or committing."

        } catch is CancellationError {
            self.errorMessage = "Apply was interrupted. Inspect the working tree before retrying; cancellation is not a rollback."
        } catch {
            self.errorMessage = error.localizedDescription
        }

        // Report actual state after every outcome; a process cancellation is not rollback.
        do {
            self.latestSnapshot = try await self.git.snapshot(of: repository, scope: .status, previous: nil)
        } catch {

            if self.errorMessage == nil {
                self.errorMessage = "The patch was applied, but the checkout could not refresh. Inspect the local changes."
            }

        }

    }

}
