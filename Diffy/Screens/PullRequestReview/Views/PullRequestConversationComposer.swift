import SwiftUI

struct PullRequestConversationComposer: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @FocusState private var isEditorFocused: Bool

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            header()
            TextEditor(text: self.$viewModel.conversationBody)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 92)
                .background(self.theme.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border))
                .focused(self.$isEditorFocused)
                .accessibilityLabel("Comment text. Markdown supported.")
            HStack(spacing: 12) {

                Label("Markdown supported · Posts to GitHub", systemImage: "text.alignleft")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer()
                Button(self.viewModel.replyingTo == nil ? "Post Comment" : "Post Reply") {
                    Task { await self.viewModel.postConversationComment() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.viewModel.account == nil || self.viewModel.conversationBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: 880)
        .frame(maxWidth: .infinity)
        .background(self.theme.surface)
        .overlay(alignment: .top) { self.theme.border.frame(height: 1) }
        .disabled(self.viewModel.isBusy)
        .onAppear { self.isEditorFocused = self.viewModel.replyingTo != nil }
        .onChange(of: self.viewModel.replyingTo?.id) { _, id in
            if id != nil { self.isEditorFocused = true }
        }

    }

    private func header() -> some View {

        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {

                Label(
                    self.viewModel.replyingTo.map { "Reply to \($0.author)" } ?? "Add to the conversation",
                    systemImage: self.viewModel.replyingTo == nil ? "text.bubble" : "arrowshape.turn.up.left"
                )
                .font(.system(size: 12, weight: .semibold))
                if let entry = self.viewModel.replyingTo, let path = entry.path {
                    Text("\(path) · \(entry.locationTitle)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

            }
            Spacer()
            if self.viewModel.replyingTo != nil {
                Button("Cancel Reply") { self.viewModel.replyingTo = nil }
                    .controlSize(.small)
            }
            Text(self.viewModel.account?.handle ?? "")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)

        }

    }

}
