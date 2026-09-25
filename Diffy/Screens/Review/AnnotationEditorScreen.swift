import SwiftUI

struct AnnotationEditorScreen: View {

    let draft: AnnotationDraft
    @ObservedObject var workspace: WorkspaceViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme
    @State private var comment = ""
    @FocusState private var commentFocused: Bool

    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                Label("A note for this change", systemImage: "text.bubble")
                    .font(.system(size: 19, weight: .semibold))
                Spacer()
                DiffyBadge(title: "LOCAL ONLY", color: self.theme.accent)

            }

            VStack(alignment: .leading, spacing: 6) {

                Text(self.draft.file.path)
                    .font(.system(size: 12, weight: .medium))
                Text("\(self.draft.side.rawValue) source · lines \(self.draft.startLine)–\(self.draft.endLine)")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }

            ScrollView([.horizontal, .vertical]) {

                Text(self.draft.snippet)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)

            }
            .frame(maxHeight: 180)
            .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 8) {

                Text("YOUR COMMENT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(self.theme.secondaryText)

                TextEditor(text: self.$comment)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 130)
                    .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border))
                    .focused(self.$commentFocused)

            }

            HStack {

                Text("Your note stays with this captured version of the code.")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)

                Spacer()
                Button("Cancel") { self.dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save annotation", action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(self.comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(28)
        .frame(width: 610)
        .background(self.theme.background)
        .onAppear { self.commentFocused = true }

    }

    private func save() {

        let annotation = CodeAnnotation(
            id: UUID(),
            projectID: self.workspace.project.id,
            projectName: self.workspace.project.name,
            comparison: self.workspace.comparisonTitle,
            filePath: self.draft.side == .left ? (self.draft.file.originalPath ?? self.draft.file.path) : self.draft.file.path,
            source: self.draft.source,
            side: self.draft.side,
            startLine: self.draft.startLine,
            endLine: self.draft.endLine,
            snippet: self.draft.snippet,
            language: self.draft.file.language,
            createdAt: Date(),
            comment: self.comment,
            isResolved: false,
            comparisonMode: self.workspace.mode.rawValue
        )

        self.review.add(annotation)
        self.workspace.showsReview = true
        self.dismiss()

    }

}

#Preview {

    AnnotationEditorScreen(
        draft: MockPreviewFixtures.annotationDraft,
        workspace: mockResolve(WorkspaceViewModel.self)
    )
    .withMockPreviews()

}
