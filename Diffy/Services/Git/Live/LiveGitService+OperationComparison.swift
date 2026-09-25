import Foundation

extension LiveGitService {

    func operationComparison(
        for request: GitOperationRequest,
        before: GitRepositorySnapshot,
        in repository: GitRepositoryReference
    ) async -> GitOperationComparison? {

        guard request.showsChangeSummary else { return nil }

        do {

            let after = try await snapshot(of: repository, scope: .full, previous: nil)

            if case .fetch = request {
                return fetchedComparison(before: before, after: after)
            }

            let selection = headComparison(before: before, after: after)
            return GitOperationComparison(
                selection: selection,
                title: "\(request.summaryTitle)",
                detail: "\(before.head.displayName) · \(before.head.shortCommitID ?? "No commits") → \(after.head.shortCommitID ?? "No commits")",
                emptyMessage: "The operation completed without changing any files."
            )

        } catch {

            return GitOperationComparison(
                selection: nil,
                title: request.summaryTitle,
                detail: "The Git operation completed, but its changed-file summary could not be read.",
                emptyMessage: "Refresh the repository to inspect its current state.",
                warning: error.localizedDescription
            )

        }

    }

    private func headComparison(before: GitRepositorySnapshot, after: GitRepositorySnapshot) -> ComparisonSelection? {

        guard let afterCommit = after.head.commitID else { return nil }
        let original: ComparisonSource = before.head.commitID.map(ComparisonSource.revision) ?? .parent(of: afterCommit)
        return ComparisonSelection(left: original, right: .revision(afterCommit))

    }

    private func fetchedComparison(before: GitRepositorySnapshot, after: GitRepositorySnapshot) -> GitOperationComparison {

        let upstream = before.upstream?.name ?? after.upstream?.name
        let previousCommit = before.remoteBranches.first { $0.name == upstream }?.commitID
        let updatedCommit = after.remoteBranches.first { $0.name == upstream }?.commitID
        let selection: ComparisonSelection?
        let detail: String

        if let previousCommit, let updatedCommit {

            selection = ComparisonSelection(left: .revision(previousCommit), right: .revision(updatedCommit))
            detail = "Fetched changes to \(upstream ?? "upstream"). Your working tree is unchanged."

        } else {

            selection = nil
            detail = "Remote references were fetched. Your working tree is unchanged."

        }

        return GitOperationComparison(
            selection: selection,
            title: "Fetch Complete",
            detail: detail,
            emptyMessage: selection == nil ? "No previous tracked upstream revision is available to compare. Choose two references in Branches to inspect fetched code." : "No file changes were fetched for the tracked upstream branch."
        )

    }

}
