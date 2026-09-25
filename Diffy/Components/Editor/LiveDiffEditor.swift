import SwiftUI
import AppKit

struct LiveDiffEditor: NSViewRepresentable {

    @Binding var text: String
    let lineStatuses: [FileChangeStatus]
    let lineComparisons: [String?]
    let focusLine: Int?
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    func makeCoordinator() -> Coordinator {
        Coordinator(text: self.$text)
    }

    func makeNSView(context: Context) -> NSScrollView {

        let scrollView = NSTextView.scrollableTextView()

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.frame = scrollView.contentView.bounds
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true

        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true

        updateEditor(textView, scrollView: scrollView, context: context)
        return scrollView

    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {

        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        context.coordinator.text = self.$text
        updateEditor(textView, scrollView: scrollView, context: context)

    }

    private func updateEditor(_ textView: NSTextView, scrollView: NSScrollView, context: Context) {

        context.coordinator.isApplyingStyles = true

        if textView.string != self.text {

            let selection = textView.selectedRange()
            textView.string = self.text
            textView.setSelectedRange(clamped(selection, length: (self.text as NSString).length))

        }

        configureLayout(textView, scrollView: scrollView)
        applyStyles(to: textView)
        context.coordinator.isApplyingStyles = false
        focusRequestedLine(in: textView, coordinator: context.coordinator)

    }

    private func configureLayout(_ textView: NSTextView, scrollView: NSScrollView) {

        let wrapsLines = self.settings.editor.wrapLines

        scrollView.hasHorizontalScroller = !wrapsLines
        scrollView.backgroundColor = NSColor(self.theme.background)
        textView.backgroundColor = NSColor(self.theme.background)
        textView.drawsBackground = true
        textView.isHorizontallyResizable = !wrapsLines
        textView.textContainer?.widthTracksTextView = wrapsLines
        textView.textContainer?.containerSize = NSSize(
            width: wrapsLines ? scrollView.contentSize.width : CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainerInset = NSSize(
            width: self.contentSize.scaled(14),
            height: self.contentSize.scaled(12)
        )
        textView.insertionPointColor = NSColor(self.theme.accent)

    }

    private func applyStyles(to textView: NSTextView) {

        guard let storage = textView.textStorage else {
            return
        }

        let source = textView.string
        let fullRange = NSRange(location: 0, length: (source as NSString).length)
        let baseAttributes = editorAttributes()

        storage.beginEditing()
        storage.setAttributes(baseAttributes, range: fullRange)
        applySyntaxColors(source: source, storage: storage)
        applyDiffColors(source: source, storage: storage)
        storage.endEditing()

        textView.typingAttributes = baseAttributes

    }

    private func editorAttributes() -> [NSAttributedString.Key: Any] {

        let font = NSFont.monospacedSystemFont(
            ofSize: self.contentSize.scaled(self.settings.editor.fontSize),
            weight: .regular
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = self.contentSize.scaled(self.settings.editor.lineHeight)
        paragraphStyle.maximumLineHeight = self.contentSize.scaled(self.settings.editor.lineHeight)
        paragraphStyle.defaultTabInterval = CGFloat(self.settings.editor.tabWidth) * font.maximumAdvancement.width

        return [
            .font: font,
            .foregroundColor: NSColor(self.theme.text),
            .paragraphStyle: paragraphStyle
        ]

    }

    private func applySyntaxColors(source: String, storage: NSTextStorage) {

        apply(
            "\\b(import|final|class|struct|let|var|private|func|return|self|init|try|await|async|throw|if|else|guard|nil)\\b",
            color: NSColor(self.theme.keyword),
            source: source,
            storage: storage
        )
        apply("\\b[A-Z][A-Za-z0-9_]*\\b", color: NSColor(self.theme.type), source: source, storage: storage)
        apply("\"[^\"]*\"", color: NSColor(self.theme.string), source: source, storage: storage)
        apply("//.*$", color: NSColor(self.theme.comment), source: source, storage: storage)

    }

    private func apply(
        _ pattern: String,
        color: NSColor,
        source: String,
        storage: NSTextStorage
    ) {

        guard let expression = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return
        }

        let fullRange = NSRange(location: 0, length: (source as NSString).length)

        for match in expression.matches(in: source, range: fullRange) {
            storage.addAttribute(.foregroundColor, value: color, range: match.range)
        }

    }

    private func applyDiffColors(source: String, storage: NSTextStorage) {

        let source = source as NSString
        var location = 0
        var lineIndex = 0

        while location < source.length, lineIndex < self.lineStatuses.count {

            var lineStart = 0
            var lineEnd = 0
            var contentEnd = 0
            source.getLineStart(
                &lineStart,
                end: &lineEnd,
                contentsEnd: &contentEnd,
                for: NSRange(location: location, length: 0)
            )

            let lineRange = NSRange(location: lineStart, length: lineEnd - lineStart)
            let contentRange = NSRange(location: lineStart, length: contentEnd - lineStart)
            let status = self.lineStatuses[lineIndex]

            if status == .modified,
               self.settings.editor.highlightLevel != "Line",
               lineIndex < self.lineComparisons.count,
               let comparison = self.lineComparisons[lineIndex] {

                applyInlineDiffColors(
                    source: source.substring(with: contentRange),
                    comparison: comparison,
                    location: lineStart,
                    storage: storage
                )

            } else if let color = backgroundColor(for: status) {
                storage.addAttribute(.backgroundColor, value: color, range: lineRange)
            }

            location = lineEnd
            lineIndex += 1

        }

    }

    private func applyInlineDiffColors(source: String, comparison: String, location: Int, storage: NSTextStorage) {

        let ranges = SyntaxHighlightService().changedRanges(
            in: source,
            comparedWith: comparison,
            level: self.settings.editor.highlightLevel
        )
        let color = NSColor(self.theme.added).withAlphaComponent(self.theme.isDark ? 0.36 : 0.22)

        for range in ranges {
            storage.addAttribute(
                .backgroundColor,
                value: color,
                range: NSRange(location: location + range.location, length: range.length)
            )
        }

    }

    private func backgroundColor(for status: FileChangeStatus) -> NSColor? {

        switch status {

        case .added:
            return NSColor(self.theme.added).withAlphaComponent(self.theme.isDark ? 0.18 : 0.12)

        case .modified, .conflicted:
            return NSColor(self.theme.changed).withAlphaComponent(self.theme.isDark ? 0.18 : 0.12)

        case .removed:
            return NSColor(self.theme.removed).withAlphaComponent(self.theme.isDark ? 0.18 : 0.12)

        case .renamed, .moved:
            return NSColor(self.theme.accent).withAlphaComponent(self.theme.isDark ? 0.18 : 0.12)

        case .identical:
            return nil

        }

    }

    private func clamped(_ range: NSRange, length: Int) -> NSRange {

        let location = min(range.location, length)
        let remainingLength = max(0, length - location)

        return NSRange(location: location, length: min(range.length, remainingLength))

    }

    private func focusRequestedLine(in textView: NSTextView, coordinator: Coordinator) {

        guard let focusLine = self.focusLine,
              coordinator.focusedLine != focusLine,
              coordinator.pendingFocusLine != focusLine else {
            return
        }

        coordinator.pendingFocusLine = focusLine

        DispatchQueue.main.async {

            guard let window = textView.window else {

                coordinator.pendingFocusLine = nil
                return

            }

            let location = characterLocation(of: focusLine, in: textView.string as NSString)
            window.makeFirstResponder(textView)
            textView.setSelectedRange(NSRange(location: location, length: 0))
            textView.scrollRangeToVisible(NSRange(location: location, length: 0))
            coordinator.focusedLine = focusLine
            coordinator.pendingFocusLine = nil

        }

    }

    private func characterLocation(of lineNumber: Int, in source: NSString) -> Int {

        guard lineNumber > 1 else {
            return 0
        }

        var location = 0

        for _ in 1..<lineNumber {

            guard location < source.length else {
                return source.length
            }

            location = NSMaxRange(source.lineRange(for: NSRange(location: location, length: 0)))

        }

        return min(location, source.length)

    }

    final class Coordinator: NSObject, NSTextViewDelegate {

        var text: Binding<String>
        var isApplyingStyles = false
        var focusedLine: Int?
        var pendingFocusLine: Int?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {

            guard !self.isApplyingStyles,
                  let textView = notification.object as? NSTextView else {
                return
            }

            self.text.wrappedValue = textView.string

        }

    }

}
