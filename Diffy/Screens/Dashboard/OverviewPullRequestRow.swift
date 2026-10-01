import SwiftUI

struct OverviewPullRequestRow: View {

    let request: AssignedPullRequestSummary
    let showsRepository: Bool
    let showsAuthor: Bool
    let isGrouped: Bool
    let review: () -> Void

    var body: some View {

        DiffyPullRequestRow(
            content: PullRequestRowContent(
                request: self.request,
                details: self.request.details,
                showsRepository: self.showsRepository
            ),
            showsAuthor: self.showsAuthor,
            isGrouped: self.isGrouped,
            review: self.review
        )

    }

}
