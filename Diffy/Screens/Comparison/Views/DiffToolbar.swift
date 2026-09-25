import SwiftUI

struct DiffToolbar: View {

    @ObservedObject var viewModel: TextDiffViewModel
    let file: DiffFile
    let annotate: () -> Void
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var layoutSelection: Binding<Bool> {
        self.file.hasNoOriginalSource ? .constant(true) : self.$settings.editor.unified
    }

    private var contentSelection: Binding<Bool> {
        self.$settings.editor.collapseUnchanged
    }

    private var comparisonFile: DiffFile {
        self.viewModel.displayedFile(self.file)
    }

    var body: some View {

        GeometryReader { geometry in
            controls(compact: geometry.size.width < self.contentSize.scaled(760))

        }
        .padding(.horizontal, self.contentSize.scaled(10))
        .frame(height: self.contentSize.scaled(42))
        .background(self.theme.surface)

    }

    private func controls(compact: Bool) -> some View {

        HStack(spacing: self.contentSize.scaled(8)) {

            layoutControls(compact: compact)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Visible content", selection: self.contentSelection) {

                Text("Changes").tag(true)
                Text("File").tag(false)

            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: self.contentSize.scaled(compact ? 108 : 132))
            .controlSize(.small)
            .disabled(self.viewModel.isEditing)
            .help(self.viewModel.isEditing ? "Apply or discard the current draft to change visible content" : "Show changed regions or the whole file")

            actionControls(compact: compact)
                .frame(maxWidth: .infinity, alignment: .trailing)

        }
        .frame(maxHeight: .infinity)

    }

    private func layoutControls(compact: Bool) -> some View {

        HStack(spacing: self.contentSize.scaled(5)) {

            if !compact {

                Text("Diff")
                    .font(self.contentSize.font(size: 11, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)
                    .fixedSize(horizontal: true, vertical: true)

            }

            Picker("Diff layout", selection: self.layoutSelection) {

                Text("Split").tag(false)
                Text("Unified").tag(true)

            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: self.contentSize.scaled(compact ? 104 : 126))
            .controlSize(.small)
            .disabled(self.file.hasNoOriginalSource || self.viewModel.isEditing)
            .help(layoutHelp())

        }

    }

    private func actionControls(compact: Bool) -> some View {

        HStack(spacing: self.contentSize.scaled(5)) {

            if !compact {

                DiffyIconButton(symbol: "chevron.up", label: "Previous change") { self.viewModel.navigate(-1, file: self.comparisonFile) }
                DiffyIconButton(symbol: "chevron.down", label: "Next change") { self.viewModel.navigate(1, file: self.comparisonFile) }

                DiffyIconButton(symbol: "text.word.spacing", label: "Wrap lines", isSelected: self.settings.editor.wrapLines) { self.settings.editor.wrapLines.toggle() }

            }

            if !self.viewModel.isEditing {
                DiffyIconButton(symbol: "magnifyingglass", label: "Find in comparison") { self.viewModel.showsSearch.toggle() }
            }

            Menu {

                Toggle("Wrap lines", isOn: self.$settings.editor.wrapLines)
                Toggle("Show line numbers", isOn: self.$settings.editor.showLineNumbers)
                Toggle("Show whitespace", isOn: self.$settings.editor.showWhitespace)
                Toggle("Hide comment-only rows", isOn: self.$settings.editor.ignoreComments)
                Divider()
                Button("Larger text") { self.settings.editor.fontSize = min(20, self.settings.editor.fontSize + 1) }
                Button("Smaller text") { self.settings.editor.fontSize = max(9, self.settings.editor.fontSize - 1) }

                if compact {

                    Divider()
                    Button("Previous change") { self.viewModel.navigate(-1, file: self.comparisonFile) }
                    Button("Next change") { self.viewModel.navigate(1, file: self.comparisonFile) }
                    Button("Annotate selected lines", action: self.annotate)
                        .disabled(self.viewModel.selectionStart == nil || self.viewModel.isEditing)

                }

                if self.viewModel.isDraftModified(file: self.file) {

                    Divider()
                    Button("Discard unapplied changes") { self.viewModel.resetDraft(file: self.file) }

                }

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: self.contentSize.scaled(20))
            .help("Comparison options")

            if !compact, !self.viewModel.isEditing {

                Button(action: self.annotate) {
                    Label("Annotate", systemImage: "text.bubble")
                }
                .font(self.contentSize.font(size: 10, weight: .medium))
                .controlSize(.small)
                .disabled(self.viewModel.selectionStart == nil)
                .help("Annotate the selected line or range")

            }

        }

    }

    private func layoutHelp() -> String {

        if self.viewModel.isEditing {
            return "Apply or discard the current draft to change the comparison layout"
        }

        if self.file.hasNoOriginalSource {
            return "New files have no original version to compare"
        }

        return "Choose side-by-side or unified code comparison"

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
