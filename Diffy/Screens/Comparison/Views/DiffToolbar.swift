import SwiftUI

struct DiffToolbar: View {

    @ObservedObject var viewModel: TextDiffViewModel
    let file: DiffFile
    let annotate: () -> Void
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.diffyTheme) private var theme

    private var layoutSelection: Binding<Bool> {
        self.file.hasNoOriginalSource ? .constant(true) : self.$settings.editor.unified
    }

    var body: some View {

        ViewThatFits(in: .horizontal) {

            controls(compact: false)
            controls(compact: true)

        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(self.theme.surface)

    }

    private func controls(compact: Bool) -> some View {

        HStack(spacing: 5) {

            Picker("Diff layout", selection: self.layoutSelection) {

                Text("Split").tag(false)
                Text("Unified").tag(true)

            }
            .pickerStyle(.segmented)
            .frame(width: compact ? 104 : 126)
            .controlSize(.small)
            .disabled(self.file.hasNoOriginalSource)
            .help(self.file.hasNoOriginalSource ? "New files have no original version to compare" : "Choose side-by-side or unified code comparison")

            Spacer(minLength: 4)

            DiffyIconButton(symbol: "chevron.up", label: "Previous change") { self.viewModel.navigate(-1, file: self.file) }
            DiffyIconButton(symbol: "chevron.down", label: "Next change") { self.viewModel.navigate(1, file: self.file) }

            if !compact {

                DiffyIconButton(symbol: "text.word.spacing", label: "Wrap lines", isSelected: self.settings.editor.wrapLines) { self.settings.editor.wrapLines.toggle() }

            }

            DiffyIconButton(symbol: "magnifyingglass", label: "Find in comparison") { self.viewModel.showsSearch.toggle() }

            Menu {

                Toggle("Wrap lines", isOn: self.$settings.editor.wrapLines)
                Toggle("Show line numbers", isOn: self.$settings.editor.showLineNumbers)
                Toggle("Show whitespace", isOn: self.$settings.editor.showWhitespace)
                Toggle("Collapse unchanged regions", isOn: self.$settings.editor.collapseUnchanged)
                Toggle("Hide comment-only rows", isOn: self.$settings.editor.ignoreComments)
                Divider()
                Button("Larger text") { self.settings.editor.fontSize = min(20, self.settings.editor.fontSize + 1) }
                Button("Smaller text") { self.settings.editor.fontSize = max(9, self.settings.editor.fontSize - 1) }

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 20)
            .help("Comparison options")

            Button(action: self.annotate) {
                Label("Annotate", systemImage: "text.bubble")
            }
            .font(.system(size: 10, weight: .medium))
            .controlSize(.small)
            .disabled(self.viewModel.selectionStart == nil)
            .help("Annotate the selected line or range")

        }

    }

}

#Preview {

    DiffToolbar(
        viewModel: mockResolve(TextDiffViewModel.self),
        file: MockPreviewFixtures.textFile
    ) {}
    .frame(width: 700)
    .withMockPreviews()

}
