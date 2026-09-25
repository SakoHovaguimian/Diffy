import SwiftUI

struct CodeLineView: View {

    @Environment(\.diffyTheme) private var theme
    @EnvironmentObject private var settings: SettingsViewModel

    let source: String?
    let number: Int?
    let status: FileChangeStatus
    let side: SourceSide
    let selected: Bool
    let annotated: Bool
    let emphasis: String?
    let action: () -> Void
    let annotate: () -> Void

    private var changeColor: Color {

        switch self.status {

        case .modified: self.theme.changed
        case .added: self.theme.added
        case .removed: self.theme.removed
        default: self.theme.modified

        }

    }

    private var changeMarker: String {

        guard self.source != nil else {
            return ""
        }

        return switch self.status {

        case .modified: "~"
        case .added: "+"
        case .removed: "−"
        default: ""

        }

    }

    private var backgroundColor: Color {

        if self.selected {
            return self.theme.selection
        }

        if self.source == nil {
            return .clear
        }

        if self.status == .identical {
            return .clear
        }

        return self.changeColor.opacity(self.theme.isDark ? 0.13 : 0.10)

    }

    var body: some View {

        HStack(alignment: .top, spacing: 0) {

            gutter()

            Text(SyntaxHighlightService().highlight(
                self.source ?? " ",
                theme: self.theme,
                whitespace: self.settings.editor.showWhitespace,
                emphasis: self.settings.editor.highlightLevel == "Line" ? nil : self.emphasis
            ))
            .font(editorFont())
            .lineSpacing(5)
            .frame(maxWidth: .infinity, minHeight: self.settings.editor.lineHeight, alignment: .topLeading)
            .padding(.top, 5)
            .padding(.trailing, 12)
            .fixedSize(horizontal: !self.settings.editor.wrapLines, vertical: true)

        }
        .frame(maxWidth: .infinity, minHeight: self.settings.editor.lineHeight, alignment: .leading)
        .background(self.backgroundColor)
        .contentShape(Rectangle())
        .onTapGesture(perform: self.action)
        .contextMenu {

            if self.number != nil {
                Button("Annotate this line", action: self.annotate)
                Button("Copy line") { ExportController.copy(self.source ?? "") }
            }

        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.side.rawValue), line \(self.number.map(String.init) ?? "empty"), \(self.source ?? "")")
        .accessibilityAction(named: "Annotate", self.annotate)

    }

    private func gutter() -> some View {

        HStack(spacing: 4) {

            if self.annotated {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(self.theme.accent)
                    .font(.system(size: 8))
            } else {
                Text(self.changeMarker)
                    .foregroundStyle(self.changeColor)
                    .font(.system(size: 10, design: .monospaced))
            }

            if self.settings.editor.showLineNumbers {

                Text(self.number.map(String.init) ?? "")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(self.selected ? self.theme.accent : self.theme.secondaryText.opacity(0.65))
                    .frame(width: 25, alignment: .trailing)

            }

        }
        .frame(width: self.settings.editor.showLineNumbers ? 54 : 20, height: self.settings.editor.lineHeight)
        .padding(.trailing, 8)
        .background(self.status == .identical || self.source == nil ? .clear : self.changeColor.opacity(0.12))

    }

    private func editorFont() -> Font {

        if self.settings.editor.fontName == "SF Mono" {
            return .system(size: self.settings.editor.fontSize, design: .monospaced)
        }

        return .custom(self.settings.editor.fontName, size: self.settings.editor.fontSize)

    }

}

#Preview {

    CodeLineView(
        source: MockPreviewFixtures.selectedLine.right,
        number: MockPreviewFixtures.selectedLine.newNumber,
        status: .modified,
        side: .right,
        selected: false,
        annotated: true,
        emphasis: nil,
        action: {},
        annotate: {}
    )
    .frame(width: 640)
    .withMockPreviews()

}
