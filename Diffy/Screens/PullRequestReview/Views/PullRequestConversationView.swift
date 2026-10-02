import SwiftUI

struct PullRequestConversationView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel

    var body: some View {

        VStack(spacing: 0) {

            ScrollView {

                VStack(alignment: .leading, spacing: 28) {

                    if let details = self.viewModel.details {
                        PullRequestDescriptionView(details: details)
                    }
                    PullRequestConversationActivityView(
                        viewModel: self.viewModel,
                        threads: self.viewModel.conversationThreads
                    )

                }
                .padding(24)
                .frame(maxWidth: 880, alignment: .leading)
                .frame(maxWidth: .infinity)

            }
            PullRequestConversationComposer(viewModel: self.viewModel)

        }

    }

}
