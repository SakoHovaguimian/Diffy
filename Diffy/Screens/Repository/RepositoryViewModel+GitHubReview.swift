import Foundation

extension RepositoryViewModel {

    func reviewPullRequest(_ request: PullRequestSummary) -> PullRequestReviewViewModel? {

        guard let link = self.linkedRepository else { return nil }
        let reviewRequest = PullRequestReviewRequest(
            number: request.number,
            title: request.title,
            webURL: request.webURL,
            link: link,
            preferredAccountID: self.selectedAccountID
        )
        return PullRequestReviewViewModel(
            request: reviewRequest,
            accounts: self.availableAccounts,
            gitHub: self.gitHub,
            diffBuilder: self.reviewDiffBuilder,
            localRepository: self.reference,
            projectID: self.project?.id
        )

    }

}
