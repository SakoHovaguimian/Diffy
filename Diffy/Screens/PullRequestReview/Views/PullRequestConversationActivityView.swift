import SwiftUI

struct PullRequestConversationActivityView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    let threads: [PullRequestConversationThread]
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        LazyVStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .firstTextBaseline, spacing: 12) {

                Text("Discussion & reviews")
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(self.viewModel.conversationCommentCount) comments · \(self.viewModel.conversationReviewCount) reviews")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }
            .padding(.bottom, 16)

            if self.threads.isEmpty {
                DiffyEmptyState(symbol: "text.bubble", title: "Start the conversation", message: "Comments, code discussions, and review decisions will appear here.")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
            ForEach(self.threads) { thread in

                DiffyTimelineRow(
                    showsPreviousConnector: thread.id != self.threads.first?.id,
                    showsNextConnector: thread.id != self.threads.last?.id,
                    color: thread.entry.color(in: self.theme)
                ) {

                    VStack(alignment: .leading, spacing: 10) {

                        commentRow(thread.entry)
                        if !thread.replies.isEmpty {

                            VStack(alignment: .leading, spacing: 10) {

                                Text("\(thread.replies.count) \(thread.replies.count == 1 ? "reply" : "replies")")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(self.theme.secondaryText)
                                ForEach(thread.replies) { reply in
                                    commentRow(reply)
                                }

                            }
                            .padding(.leading, 24)
                            .overlay(alignment: .leading) { self.theme.border.frame(width: 1).padding(.leading, 10) }

                        }

                    }

                }

            }

        }

    }

    private func commentRow(_ entry: PullRequestConversationEntry) -> some View {

        PullRequestConversationRow(
            entry: entry,
            location: self.viewModel.conversationLocation(for: entry),
            canReply: self.viewModel.account != nil && !self.viewModel.isBusy,
            openFile: { self.viewModel.openConversationComment(entry) },
            reply: { self.viewModel.replyingTo = entry }
        )

    }

}
