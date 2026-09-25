import Foundation

extension RepositoryViewModel {

    func inspectBranch(_ branch: RepositoryBranch) {

        guard let reference, let snapshot = self.snapshot else { return }
        let base = branch.isCurrent
            ? (snapshot.upstream?.name ?? snapshot.localBranches.first(where: { !$0.isCurrent })?.name ?? branch.name)
            : (snapshot.head.branchName ?? snapshot.localBranches.first?.name ?? branch.name)
        self.isLoadingBranchReview = true
        self.errorMessage = nil

        Task {

            do {
                let review = try await self.git.branchReview(in: reference, branch: branch, base: base)
                guard self.reference == reference else {
                    self.isLoadingBranchReview = false
                    return
                }
                self.comparisonReview = ComparisonReviewRequest(
                    repository: reference,
                    selection: review.selection,
                    title: "Review \(branch.name)",
                    detail: review.detail,
                    startsExpanded: false,
                    mode: .branches,
                    emptyMessage: review.emptyMessage
                )
            } catch {
                self.errorMessage = error.localizedDescription
            }

            self.isLoadingBranchReview = false

        }

    }

    func reviewViewModel(for request: ComparisonReviewRequest) -> ComparisonReviewViewModel {
        ComparisonReviewViewModel(request: request, git: self.git, diffBuilder: self.reviewDiffBuilder)
    }

    func showComparisonReview(
        _ selection: ComparisonSelection,
        title: String,
        detail: String? = nil,
        mode: ComparisonMode,
        startsExpanded: Bool = true
    ) {

        guard let reference else { return }
        self.comparisonReview = ComparisonReviewRequest(
            repository: reference,
            selection: selection,
            title: title,
            detail: detail ?? selection.title,
            startsExpanded: startsExpanded,
            mode: mode
        )

    }

    func showOperationReview(_ comparison: GitOperationComparison, in repository: GitRepositoryReference) {

        self.comparisonReview = ComparisonReviewRequest(
            repository: repository,
            selection: comparison.selection,
            title: comparison.title,
            detail: comparison.detail,
            startsExpanded: false,
            mode: .commits,
            emptyMessage: comparison.emptyMessage,
            warning: comparison.warning,
            successMessage: comparison.title == "Pull complete"
                ? (comparison.warning == nil ? "Pull completed. Review the result below." : "Pull completed, but its change summary could not be read.")
                : nil
        )

    }

}
