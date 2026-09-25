import SwiftUI

struct PullRequestNoteEditor: View {

    let draft: PullRequestNoteDraft
    let save: (String) -> Void
    @State private var comment = ""
    @FocusState private var commentFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Add Review Note")
                .font(.system(size: 18, weight: .semibold))
            Text("\(self.draft.filePath) · \(self.draft.side.rawValue) Line \(self.draft.line)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(self.theme.secondaryText)
                .textSelection(.enabled)
            Text(self.draft.snippet)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 8))
            TextEditor(text: self.$comment)
                .font(.system(size: 13))
                .frame(minHeight: 140)
                .focused(self.$commentFocused)
                .accessibilityLabel("Review Note")

            HStack {

                Spacer()
                Button("Cancel") { self.dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save Review Note") {

                    self.save(self.comment.trimmingCharacters(in: .whitespacesAndNewlines))
                    self.dismiss()

                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(self.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(24)
        .frame(width: 560)
        .background(self.theme.background)
        .onAppear { self.commentFocused = true }

    }
}
