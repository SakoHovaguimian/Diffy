import SwiftUI

struct CommandPaletteScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme
    @State private var query = ""
    @FocusState private var focused: Bool

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 12) {

                Image(systemName: "magnifyingglass").foregroundStyle(self.theme.accent)
                TextField("Where would you like to go?", text: self.$query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .focused(self.$focused)
                DiffyBadge(title: "ESC", color: self.theme.secondaryText)

            }
            .padding(24)

            Divider()

            ScrollView {

                VStack(alignment: .leading, spacing: 3) {

                    command("Open review notes", symbol: "text.bubble") { self.workspace.showsReview = true }
                    command("Create a Bucket", symbol: "folder.badge.plus") { self.workspace.addBucket() }
                    command("Project overview", symbol: "square.grid.2x2") { self.workspace.showDashboard() }

                    ForEach(ComparisonMode.allCases) { mode in
                        command("Compare · \(mode.rawValue)", symbol: mode.symbol) { self.workspace.selectMode(mode) }
                    }

                    ForEach(self.workspace.project.files) { file in
                        command(file.path, symbol: "doc.text") { self.workspace.selectFile(file) }
                    }

                }
                .padding(12)

            }
            .frame(height: 370)

            HStack {

                Text("Navigate with Tab · Return to open")
                Spacer()
                Text("\(self.workspace.project.name)")

            }
            .font(.system(size: 10))
            .foregroundStyle(self.theme.secondaryText)
            .padding(16)

        }
        .frame(width: 620)
        .background(self.theme.surface)
        .onAppear { self.focused = true }
        .onExitCommand { self.dismiss() }

    }

    @ViewBuilder
    private func command(_ title: String, symbol: String, action: @escaping @MainActor @Sendable () -> Void) -> some View {

        if self.query.isEmpty || title.localizedCaseInsensitiveContains(self.query) {

            Button {

                self.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: action)

            } label: {

                HStack(spacing: 12) {

                    Image(systemName: symbol).foregroundStyle(self.theme.secondaryText).frame(width: 18)
                    Text(title).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Image(systemName: "return").font(.system(size: 9)).foregroundStyle(self.theme.secondaryText)

                }
                .font(.system(size: 12))
                .padding(11)
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)

        }

    }

}

#Preview {

    CommandPaletteScreen(
        workspace: mockResolve(WorkspaceViewModel.self)
    )
    .withMockPreviews()

}
