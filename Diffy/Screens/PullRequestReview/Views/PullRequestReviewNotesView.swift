import SwiftUI

struct PullRequestReviewNotesView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var aiWorkspace: AIReviewWorkspaceViewModel
    let notes: [CodeAnnotation]
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("Review Notes For This Revision")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(self.notes.count) Open")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)

            }
            if self.notes.isEmpty {
                Text("Use the note action beside a diff line to capture review context for AI.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
            } else {
                noteActions()
                noteList()
            }

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func noteActions() -> some View {

        HStack {

            Button {
                self.aiWorkspace.addressSelectedNotes()
                self.viewModel.selectedTab = .aiNotes
            } label: {
                Label("Ask AI To Address Notes", systemImage: "sparkles")
            }
            .buttonStyle(.borderedProminent)
            .disabled(self.aiWorkspace.selectedAnnotations.isEmpty || self.aiWorkspace.isBusy)

            Text("\(self.aiWorkspace.selectedAnnotations.count) Selected")
                .font(.system(size: 10))
                .foregroundStyle(self.theme.secondaryText)

        }

    }

    private func noteList() -> some View {

        ScrollView(.horizontal) {

            HStack(alignment: .top, spacing: 10) {
                ForEach(self.notes) { note in noteRow(note) }
            }

        }

    }

    private func noteRow(_ note: CodeAnnotation) -> some View {

        HStack(alignment: .top, spacing: 8) {

            Toggle("Select Note", isOn: Binding(
                get: { self.aiWorkspace.selectedAnnotationIDs.contains(note.id) },
                set: { self.aiWorkspace.setAnnotationSelected(note.id, selected: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)
            .accessibilityLabel("Select Review Note On \(note.filePath) Line \(note.startLine)")

            Button {
                self.viewModel.openFile(path: note.filePath)
            } label: {

                VStack(alignment: .leading, spacing: 5) {

                    Text("\(note.filePath) · \(note.side.rawValue) \(note.startLine)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.accent)
                        .lineLimit(1)
                    Text(note.comment)
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.text)
                        .lineLimit(2)

                }
                .frame(width: 240, alignment: .leading)
                .padding(10)
                .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 8))

            }
            .buttonStyle(.plain)

        }

    }
}
