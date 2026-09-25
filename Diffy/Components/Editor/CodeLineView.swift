import SwiftUI
import AppKit

struct CodeLineView: View {

    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @EnvironmentObject private var settings: SettingsViewModel

    let source: String?
    let oppositeSource: String?
    let number: Int?
    let status: FileChangeStatus
    let side: SourceSide
    let selected: Bool
    let annotated: Bool
    let emphasis: String?
    let paneWidth: CGFloat
    let action: () -> Void
    var edit: (() -> Void)? = nil
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

        if self.status == .modified, self.oppositeSource != nil, self.settings.editor.highlightLevel != "Line" {
            return .clear
        }

        return self.changeColor.opacity(self.theme.isDark ? 0.13 : 0.10)

    }

    var body: some View {

        HStack(alignment: .top, spacing: 0) {

            gutter()

            Text(highlightedSource())
            .font(editorFont())
            .lineSpacing(self.contentSize.scaled(5))
            .frame(maxWidth: .infinity, minHeight: self.contentSize.scaled(self.settings.editor.lineHeight), alignment: .topLeading)
            .padding(.top, self.contentSize.scaled(5))
            .padding(.trailing, self.contentSize.scaled(12))
            .fixedSize(horizontal: !self.settings.editor.wrapLines, vertical: true)
            .contentShape(Rectangle())
            .onTapGesture(perform: sourceAction)
            .help(self.edit == nil ? "Select This Line" : "Click To Edit The Working Copy")

        }
        .frame(maxWidth: .infinity, minHeight: self.contentSize.scaled(self.settings.editor.lineHeight), alignment: .leading)
        .background(self.backgroundColor)
        .contentShape(Rectangle())
        .contextMenu {

            if self.number != nil {

                Button("Annotate This Line", action: self.annotate)
                Button("Copy Line") { ExportController.copy(self.source ?? "") }

            }

        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.side.rawValue), Line \(self.number.map(String.init) ?? "Empty"), \(self.source ?? "")")
        .accessibilityAction(named: "Annotate", self.annotate)
        .accessibilityAction(named: "Edit Working Copy") { self.edit?() }

    }

    private func gutter() -> some View {

        HStack(spacing: self.contentSize.scaled(4)) {

            if self.annotated {

                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(self.theme.accent)
                    .font(self.contentSize.font(size: 8))

            } else {

                Text(self.changeMarker)
                    .foregroundStyle(self.changeColor)
                    .font(self.contentSize.font(size: 10, design: .monospaced))

            }

            if self.settings.editor.showLineNumbers {

                Text(self.number.map(String.init) ?? "")
                    .font(self.contentSize.font(size: 10, design: .monospaced))
                    .foregroundStyle(self.selected ? self.theme.accent : self.theme.secondaryText.opacity(self.theme.isDark ? 0.65 : 0.85))
                    .frame(width: self.contentSize.scaled(25), alignment: .trailing)

            }

        }
        .frame(
            width: self.contentSize.scaled(self.settings.editor.showLineNumbers ? 54 : 20),
            height: self.contentSize.scaled(self.settings.editor.lineHeight)
        )
        .padding(.trailing, self.contentSize.scaled(8))
        .background(self.status == .identical || self.source == nil ? .clear : self.changeColor.opacity(0.12))
        .contentShape(Rectangle())
        .onTapGesture(perform: self.action)

    }

    private func sourceAction() {

        if let edit = self.edit {
            edit()
        } else {
            self.action()
        }

    }

    private func editorFont() -> Font {

        if self.settings.editor.fontName == "SF Mono" {
            return self.contentSize.font(size: self.settings.editor.fontSize, design: .monospaced)
        }

        return .custom(self.settings.editor.fontName, size: self.contentSize.scaled(self.settings.editor.fontSize))

    }

    private func highlightedSource() -> AttributedString {

        let source = self.source ?? " "
        let highlighted = SyntaxHighlightService().highlight(
            source,
            theme: self.theme,
            whitespace: self.settings.editor.showWhitespace,
            comparison: self.status == .modified ? self.oppositeSource : nil,
            highlightLevel: self.settings.editor.highlightLevel,
            inlineColor: self.side == .left ? self.theme.removed : self.theme.added,
            emphasis: self.settings.editor.highlightLevel == "Line" ? nil : self.emphasis
        )

        guard self.settings.editor.wrapLines, self.source != nil else {
            return highlighted
        }

        let styledSource = NSMutableAttributedString(attributedString: NSAttributedString(highlighted))
        let font = wrappingFont()
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        let availableWidth = self.paneWidth - self.contentSize.scaled(self.settings.editor.showLineNumbers ? 74 : 40)
        let lineColumns = max(8, Int((availableWidth / spaceWidth).rounded(.down)) - 2)
        let continuationColumns = continuationIndent(for: source, lineColumns: lineColumns)
        let breaks = wrapBreaks(
            in: source,
            lineColumns: lineColumns,
            continuationColumns: continuationColumns,
            font: font,
            spaceWidth: spaceWidth
        )

        for offset in breaks.reversed() {

            var attributes = styledSource.attributes(at: offset - 1, effectiveRange: nil)
            attributes.removeValue(forKey: .backgroundColor)
            attributes.removeValue(forKey: NSAttributedString.Key("SwiftUI.BackgroundColor"))
            let continuation = NSAttributedString(
                string: "\n" + String(repeating: " ", count: continuationColumns),
                attributes: attributes
            )
            styledSource.insert(continuation, at: offset)

        }

        return AttributedString(styledSource)

    }

    private func continuationIndent(for source: String, lineColumns: Int) -> Int {

        let leadingWhitespace = source.prefix { $0 == " " || $0 == "\t" }
        var columns = 0

        for character in leadingWhitespace {

            if character == "\t" {
                let tabWidth = max(1, self.settings.editor.tabWidth)
                columns += tabWidth - columns % tabWidth
            } else {
                columns += 1
            }

        }

        return min(max(columns, 2), min(20, max(2, lineColumns / 3)))

    }

    private func wrapBreaks(
        in source: String,
        lineColumns: Int,
        continuationColumns: Int,
        font: NSFont,
        spaceWidth: CGFloat
    ) -> [Int] {

        var breaks: [Int] = []
        var column = 0

        for index in source.indices {

            let character = source[index]
            let width = characterWidth(character, at: column, font: font, spaceWidth: spaceWidth)

            if column > 0 && column + width > lineColumns {

                breaks.append(source.utf16.distance(from: source.startIndex, to: index))
                column = continuationColumns

            }

            column += characterWidth(character, at: column, font: font, spaceWidth: spaceWidth)

        }

        return breaks

    }

    private func characterWidth(_ character: Character, at column: Int, font: NSFont, spaceWidth: CGFloat) -> Int {

        if character == "\t" {

            let tabWidth = max(1, self.settings.editor.tabWidth)
            return tabWidth - column % tabWidth

        }

        if character.asciiValue != nil {
            return 1
        }

        let measuredWidth = (String(character) as NSString).size(withAttributes: [.font: font]).width
        return max(1, Int((measuredWidth / spaceWidth).rounded()))

    }

    private func wrappingFont() -> NSFont {

        let fontSize = self.contentSize.scaled(self.settings.editor.fontSize)

        return NSFont(name: self.settings.editor.fontName, size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

    }

}

#Preview {

    CodeLineView(
        source: MockPreviewFixtures.selectedLine.right,
        oppositeSource: MockPreviewFixtures.selectedLine.left,
        number: MockPreviewFixtures.selectedLine.newNumber,
        status: .modified,
        side: .right,
        selected: false,
        annotated: true,
        emphasis: nil,
        paneWidth: 640,
        action: {},
        annotate: {}
    )
    .frame(width: 640)
    .withMockPreviews()

}
