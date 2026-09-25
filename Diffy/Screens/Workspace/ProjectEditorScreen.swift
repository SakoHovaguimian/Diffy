import SwiftUI

struct ProjectEditorScreen: View {

    @Binding var draft: ProjectEditorDraft
    let bucket: Bucket?
    let errorMessage: String?
    let save: (ProjectEditorDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme

    private let symbols = [
        "folder.fill", "square.stack.3d.up.fill", "app.fill", "hammer.fill",
        "server.rack", "chevron.left.forwardslash.chevron.right", "book.closed.fill", "sparkles"
    ]

    var body: some View {

        let accent = self.bucket.map { Color(hex: $0.accentHex) } ?? self.theme.accent

        VStack(alignment: .leading, spacing: 20) {

            Text(self.draft.isEditing ? "Edit Project" : "Add New Project")
                .font(.system(size: 25, weight: .semibold))

            Text(projectDescription())
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)

            HStack(spacing: 12) {

                Image(systemName: self.draft.symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(accent)
                    .frame(width: 46, height: 46)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                TextField("Display name", text: self.$draft.displayName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .accessibilityLabel("Project display name")

            }

            Text("ICON")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(self.theme.secondaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {

                ForEach(self.symbols, id: \.self) { symbol in

                    Button {
                        self.draft.symbol = symbol
                    } label: {

                        Image(systemName: symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(self.draft.symbol == symbol ? accent : self.theme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(self.draft.symbol == symbol ? accent.opacity(0.12) : self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.draft.symbol == symbol ? accent : self.theme.border))

                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(symbol)

                }

            }

            projectReference(label: "REPOSITORY", value: self.draft.repositoryName)

            if let directoryURL = self.draft.directoryURL {
                projectReference(label: "FOLDER", value: directoryURL.path)
            }

            if let errorMessage = self.errorMessage {
                DiffyStatusBanner(message: errorMessage, isError: true)
            }

            HStack {

                Label(self.bucket?.title ?? "Unassigned", systemImage: self.bucket?.symbol ?? "tray")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(accent)

                Spacer()
                Button("Cancel") { self.dismiss() }.keyboardShortcut(.cancelAction)
                Button(self.draft.isEditing ? "Save Changes" : "Add Project") {
                    self.save(self.draft)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(self.draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(28)
        .frame(width: 500)
        .background(self.theme.background)
        .interactiveDismissDisabled()

    }

    private func projectDescription() -> String {

        if self.draft.isEditing {
            return "Choose the name and icon shown in Diffy. Your repository name and GitHub link stay the same."
        }

        guard let bucket = self.bucket else {
            return "Name this folder and choose an icon. It will start in Unassigned."
        }

        return "Name this folder and choose an icon. Its color follows the \(bucket.title) Bucket."

    }

    private func projectReference(label: String, value: String) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundStyle(self.theme.secondaryText)

            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .truncationMode(.middle)

        }

    }

}

#Preview {

    ProjectEditorScreen(
        draft: .constant(ProjectEditorDraft(
            directoryURL: URL(fileURLWithPath: "/Users/example/Projects/Rune", isDirectory: true),
            bucketID: "personal"
        )),
        bucket: MockWorkspaceFixtures.buckets[0],
        errorMessage: nil,
        save: { _ in }
    )
    .withMockPreviews()

}
