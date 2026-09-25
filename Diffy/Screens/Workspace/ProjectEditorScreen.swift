import SwiftUI

struct ProjectEditorScreen: View {

    @State var draft: NewProjectDraft
    let bucket: Bucket
    let save: (NewProjectDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme

    private let symbols = [
        "folder.fill", "square.stack.3d.up.fill", "app.fill", "hammer.fill",
        "server.rack", "chevron.left.forwardslash.chevron.right", "book.closed.fill", "sparkles"
    ]

    var body: some View {

        let accent = Color(hex: self.bucket.accentHex)

        VStack(alignment: .leading, spacing: 20) {

            Text("Add New Project")
                .font(.system(size: 25, weight: .semibold))

            Text("Name this folder and choose an icon. Its color follows the \(self.bucket.title) Bucket.")
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)

            HStack(spacing: 12) {

                Image(systemName: self.draft.symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(accent)
                    .frame(width: 46, height: 46)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                TextField("Project name", text: self.$draft.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))

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

            VStack(alignment: .leading, spacing: 6) {

                Text("FOLDER")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(self.theme.secondaryText)

                Text(self.draft.directoryPath)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)

            }

            HStack {

                Label(self.bucket.title, systemImage: self.bucket.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(accent)

                Spacer()
                Button("Cancel") { self.dismiss() }.keyboardShortcut(.cancelAction)
                Button("Add Project") {

                    self.save(self.draft)
                    self.dismiss()

                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(self.draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(28)
        .frame(width: 500)
        .background(self.theme.background)

    }

}

#Preview {

    ProjectEditorScreen(
        draft: NewProjectDraft(
            directoryPath: "/Users/example/Projects/Rune",
            bucketID: "ios",
            name: "Rune"
        ),
        bucket: MockWorkspaceFixtures.buckets[0],
        save: { _ in }
    )
    .withMockPreviews()

}
