import Foundation

extension RepositoryViewModel {

    func reviewPullRequest(_ request: PullRequestSummary) {

        guard let link = self.linkedRepository else { return }
        let reviewRequest = PullRequestReviewRequest(
            number: request.number,
            title: request.title,
            webURL: request.webURL,
            link: link,
            preferredAccountID: self.selectedAccountID
        )
        self.gitHubReview = PullRequestReviewViewModel(request: reviewRequest, accounts: self.availableAccounts, gitHub: self.gitHub)

    }

}
