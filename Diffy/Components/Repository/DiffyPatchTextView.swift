import SwiftUI
import AppKit

/// A read-only native code surface; selection, copy, find, and scrolling stay native.
struct DiffyPatchTextView: NSViewRepresentable {

    let text: String
    let theme: DiffyTheme
    let fontSize: CGFloat

    func makeNSView(context: Context) -> NSScrollView {

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = false
        let editor = NSTextView()
        editor.isEditable = false
        editor.isSelectable = true
        editor.isRichText = false
        editor.usesFindBar = true
        editor.isHorizontallyResizable = true
        editor.isVerticallyResizable = true
        editor.textContainerInset = NSSize(width: 18, height: 16)
        editor.textContainer?.widthTracksTextView = false
        editor.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.autoresizingMask = [.width]
        editor.setAccessibilityLabel("Git comparison. Read-only patch.")
        scroll.documentView = editor
        return scroll

    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {

        guard let editor = scroll.documentView as? NSTextView else { return }
        let displayText = String(self.text.prefix(1_000_000))
        let signature = "\(self.theme.isDark)-\(self.fontSize)-\(NSColor(self.theme.accent))"

        guard context.coordinator.text != displayText || context.coordinator.signature != signature else { return }
        context.coordinator.text = displayText
        context.coordinator.signature = signature
        let attributed = NSMutableAttributedString(string: displayText, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: self.fontSize, weight: .regular),
            .foregroundColor: NSColor(self.theme.text)
        ])
        let source = displayText as NSString
        var location = 0

        while location < source.length {

            let range = source.lineRange(for: NSRange(location: location, length: 0))
            let line = source.substring(with: range)
            let color: Color?

            if line.hasPrefix("+") {
                color = self.theme.added
            } else if line.hasPrefix("-") {
                color = self.theme.removed
            } else if line.hasPrefix("@@") || line.hasPrefix("diff --git") {
                color = self.theme.accent
            } else {
                color = nil
            }

            if let color {
                attributed.addAttribute(.foregroundColor, value: NSColor(color), range: range)
            }

            location = NSMaxRange(range)

        }

        editor.backgroundColor = NSColor(self.theme.surface)
        editor.textStorage?.setAttributedString(attributed)
        editor.scrollToBeginningOfDocument(nil)

    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var text = ""
        var signature = ""
    }

}
