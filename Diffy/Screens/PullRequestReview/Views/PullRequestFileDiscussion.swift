import SwiftUI

struct PullRequestFileDiscussion: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    let drafts: [PullRequestReviewCommentDraft]
    let comments: [PullRequestConversationEntry]
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        if !self.drafts.isEmpty || !self.comments.isEmpty {

            LazyVStack(alignment: .leading, spacing: 14) {

                ForEach(self.drafts) { draft in

                    VStack(alignment: .leading, spacing: 8) {

                        HStack {

                            Label("Pending · \(draft.side == "LEFT" ? "Old" : "New") Line \(draft.line)", systemImage: "text.bubble")
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(self.theme.accent)
                            Spacer()
                            Button("Edit") { self.viewModel.commentEditor = draft }
                            Button("Remove", role: .destructive) { self.viewModel.drafts.removeAll { $0.id == draft.id } }

                        }
                        Text(draft.body).font(.system(size: 12)).textSelection(.enabled)

                    }
                    .padding(14)
                    .background(self.theme.selection, in: RoundedRectangle(cornerRadius: 8))

                }
                ForEach(self.comments) { entry in
                    PullRequestConversationRow(entry: entry) {

                        self.viewModel.replyingTo = entry
                        self.viewModel.selectedTab = .conversation

                    }
                }

            }
            .padding(16)
            .frame(maxWidth: 900, alignment: .leading)
            .disabled(self.viewModel.isBusy)

        }

    }

}
