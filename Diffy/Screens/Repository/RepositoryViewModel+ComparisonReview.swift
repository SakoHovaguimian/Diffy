import Foundation

extension RepositoryViewModel {

    func reviewViewModel(for request: ComparisonReviewRequest) -> ComparisonReviewViewModel {
        ComparisonReviewViewModel(request: request, git: self.git, diffBuilder: self.reviewDiffBuilder)
    }

    func showComparisonReview(
        _ selection: ComparisonSelection,
        title: String,
        detail: String? = nil,
        mode: ComparisonMode
    ) {

        guard let reference else { return }
        self.comparisonReview = ComparisonReviewRequest(
            repository: reference,
            selection: selection,
            title: title,
            detail: detail ?? selection.title,
            startsExpanded: true,
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
            warning: comparison.warning
        )

    }

}
