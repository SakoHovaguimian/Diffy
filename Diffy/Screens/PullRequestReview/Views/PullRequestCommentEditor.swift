import SwiftUI

struct PullRequestCommentEditor: View {

    @State var draft: PullRequestReviewCommentDraft
    let save: (PullRequestReviewCommentDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Add review comment").font(.system(size: 20, weight: .semibold))
            Text("\(self.draft.path) · \(self.draft.side == "LEFT" ? "old" : "new") line \(self.draft.line)")
                .font(.system(size: 11, design: .monospaced)).foregroundStyle(self.theme.secondaryText)
            TextEditor(text: self.$draft.body)
                .font(.system(size: 13)).frame(minHeight: 160)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(self.theme.border))
                .accessibilityLabel("Review comment. Markdown supported.")
            Text("Markdown supported. This comment is sent when you submit your review.")
                .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            HStack {

                Button("Cancel", role: .cancel) { self.dismiss() }
                Spacer()
                Button("Add to review") {

                    self.save(self.draft)
                    self.dismiss()

                }
                .buttonStyle(.borderedProminent)
                .disabled(self.draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(24)
        .frame(width: 580)
        .interactiveDismissDisabled(!self.draft.body.isEmpty)

    }

}
