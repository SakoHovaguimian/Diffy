import SwiftUI

struct DiffToolbar: View {

    @ObservedObject var viewModel: TextDiffViewModel
    let file: DiffFile
    var reviewLayout: Binding<Bool>? = nil
    let annotate: () -> Void
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var layoutSelection: Binding<Bool> {
        self.file.hasNoOriginalSource ? .constant(true) : (self.reviewLayout ?? self.$settings.editor.unified)
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

            Picker("Visible Content", selection: self.contentSelection) {

                Text("Changes").tag(true)
                Text(self.reviewLayout == nil ? "File" : "Patch").tag(false)

            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: self.contentSize.scaled(compact ? 108 : 132))
            .controlSize(.small)
            .disabled(self.viewModel.isEditing)
            .help(self.viewModel.isEditing
                ? "Apply Or Discard The Current Draft To Change Visible Content"
                : (self.reviewLayout == nil ? "Show Changed Regions Or The Whole File" : "Show Changed Regions Or All Lines In The GitHub Patch"))

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

            Picker("Diff Layout", selection: self.layoutSelection) {

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

                DiffyIconButton(symbol: "chevron.up", label: "Previous Change") { self.viewModel.navigate(-1, file: self.comparisonFile) }
                DiffyIconButton(symbol: "chevron.down", label: "Next Change") { self.viewModel.navigate(1, file: self.comparisonFile) }

                DiffyIconButton(symbol: "text.word.spacing", label: "Wrap Lines", isSelected: self.settings.editor.wrapLines) { self.settings.editor.wrapLines.toggle() }

            }

            if !self.viewModel.isEditing {
                DiffyIconButton(symbol: "magnifyingglass", label: "Find In Comparison") { self.viewModel.showsSearch.toggle() }
            }

            Menu {

                Toggle("Wrap Lines", isOn: self.$settings.editor.wrapLines)
                Toggle("Show Line Numbers", isOn: self.$settings.editor.showLineNumbers)
                Toggle("Show Whitespace", isOn: self.$settings.editor.showWhitespace)
                Toggle("Hide Comment-Only Rows", isOn: self.$settings.editor.ignoreComments)
                Divider()
                Button("Larger Text") { self.settings.editor.fontSize = min(20, self.settings.editor.fontSize + 1) }
                Button("Smaller Text") { self.settings.editor.fontSize = max(9, self.settings.editor.fontSize - 1) }

                if compact {

                    Divider()
                    Button("Previous Change") { self.viewModel.navigate(-1, file: self.comparisonFile) }
                    Button("Next Change") { self.viewModel.navigate(1, file: self.comparisonFile) }
                    Button(self.reviewLayout == nil ? "Annotate Selected Lines" : "Add Review Note On Selected Line", action: self.annotate)
                        .disabled(self.viewModel.selectionStart == nil || self.viewModel.isEditing)

                }

                if self.viewModel.isDraftModified(file: self.file) {

                    Divider()
                    Button("Discard Unapplied Changes") { self.viewModel.resetDraft(file: self.file) }

                }

            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .frame(width: self.contentSize.scaled(20))
            .help("Comparison Options")

            if !compact, !self.viewModel.isEditing {

                Button(action: self.annotate) {
                    Label(self.reviewLayout == nil ? "Annotate" : "Add Review Note", systemImage: "text.bubble")
                }
                .font(self.contentSize.font(size: 10, weight: .medium))
                .controlSize(.small)
                .disabled(self.viewModel.selectionStart == nil)
                .help("Annotate The Selected Line Or Range")

            }

        }

    }

    private func layoutHelp() -> String {

        if self.viewModel.isEditing {
            return "Apply Or Discard The Current Draft To Change The Comparison Layout"
        }

        if self.file.hasNoOriginalSource {
            return "New files have no original version to compare"
        }

        return "Choose Side-By-Side Or Unified Code Comparison"

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
