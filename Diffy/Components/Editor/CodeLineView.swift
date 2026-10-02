import SwiftUI
import AppKit

struct CodeLineView: View {

    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @EnvironmentObject private var settings: SettingsViewModel

    let filePath: String
    let language: String
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
    var comment: (() -> Void)? = nil
    var reviewNote: (() -> Void)? = nil

    private var lineGutterWidth: CGFloat {
        DiffLineGutter.width(showsLineNumbers: self.settings.editor.showLineNumbers, hasComment: self.comment != nil)
    }

    private var clipboardContent: DiffLineClipboardContent? {

        guard let source = self.source, let number = self.number else { return nil }

        return DiffLineClipboardContent(
            filePath: self.filePath,
            lineNumber: number,
            side: self.side,
            source: source,
            language: self.language
        )

    }

    private var changeColor: Color {

        switch self.status {

        case .modified: self.theme.changed
        case .added: self.theme.added
        case .removed: self.theme.removed
        default: self.status.color(in: self.theme)

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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(self.side.rawValue), Line \(self.number.map(String.init) ?? "Empty"), \(self.source ?? "")")
        .accessibilityAction(named: "Annotate", self.annotate)
        .accessibilityAction(named: "Edit Working Copy") { self.edit?() }

    }

    private func gutter() -> some View {

        DiffLineGutter(
            number: self.number,
            marker: self.changeMarker,
            markerColor: self.changeColor,
            selected: self.selected,
            annotated: self.annotated,
            showsLineNumbers: self.settings.editor.showLineNumbers,
            lineHeight: self.settings.editor.lineHeight,
            clipboardContent: self.clipboardContent,
            select: self.action,
            annotate: self.annotate,
            annotationTitle: self.reviewNote == nil ? "Annotate This Line" : "Add Review Note On This Line",
            comment: self.comment
        )
        .background(self.status == .identical || self.source == nil ? .clear : self.changeColor.opacity(0.12))

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

        CodeLineTextRenderer.shared.render(
            source: self.source,
            comparison: self.status == .modified ? self.oppositeSource : nil,
            theme: self.theme,
            preferences: self.settings.editor,
            contentSize: self.contentSize,
            paneWidth: self.paneWidth,
            gutterWidth: self.lineGutterWidth,
            inlineColor: self.side == .left ? self.theme.removed : self.theme.added,
            emphasis: self.settings.editor.highlightLevel == "Line" ? nil : self.emphasis
        )

    }

}

#Preview {

    CodeLineView(
        filePath: "Sources/NavigationService.swift",
        language: "swift",
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
