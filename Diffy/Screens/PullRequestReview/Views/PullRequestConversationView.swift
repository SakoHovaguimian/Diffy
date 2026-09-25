import SwiftUI

struct PullRequestConversationView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            ScrollView {

                LazyVStack(alignment: .leading, spacing: 18) {

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Description").font(.system(size: 15, weight: .semibold))
                        Text(self.viewModel.details?.body.isEmpty == false ? self.viewModel.details?.body ?? "" : "No description provided.")
                            .font(.system(size: 13)).textSelection(.enabled)

                    }
                    .padding(.bottom, 8)
                    ForEach(self.viewModel.conversation) { entry in
                        PullRequestConversationRow(entry: entry) { self.viewModel.replyingTo = entry }
                    }

                }
                .padding(24)
                .frame(maxWidth: 1000, alignment: .leading)
                .frame(maxWidth: .infinity)
                .disabled(self.viewModel.isBusy)

            }
            VStack(alignment: .leading, spacing: 10) {

                HStack {

                    Text(self.viewModel.replyingTo.map { "Reply to \($0.author) · \($0.path ?? "")" } ?? "Add to the conversation")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    if self.viewModel.replyingTo != nil {
                        Button("Cancel reply") { self.viewModel.replyingTo = nil }
                    }
                    Text(self.viewModel.account?.handle ?? "").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)

                }
                TextEditor(text: self.$viewModel.conversationBody)
                    .font(.system(size: 12)).frame(height: 75)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(self.theme.border))
                    .accessibilityLabel("Comment text. Markdown supported.")
                HStack {

                    Text("Markdown supported · Posts immediately to GitHub").font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)
                    Spacer()
                    Button(self.viewModel.replyingTo == nil ? "Post comment" : "Post reply") {
                        Task { await self.viewModel.postConversationComment() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(self.viewModel.account == nil || self.viewModel.conversationBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                }

            }
            .padding(20)
            .background(self.theme.surface)
            .disabled(self.viewModel.isBusy)

        }

    }

}
