import SwiftUI
import AppKit

/// Keeps width-independent highlighting and column-based wrapping out of repeated view updates.
@MainActor
final class CodeLineTextRenderer {

    static let shared = CodeLineTextRenderer()
    private let cache = NSCache<CacheKey, RenderedLine>()

    private init() {

        self.cache.countLimit = 4096
        self.cache.totalCostLimit = 16 * 1024 * 1024

    }

    func render(
        source: String?,
        comparison: String?,
        theme: DiffyTheme,
        preferences: EditorPreferences,
        contentSize: DiffyContentSize,
        paneWidth: CGFloat,
        gutterWidth: CGFloat,
        inlineColor: Color,
        emphasis: String?
    ) -> AttributedString {

        let key = CodeLineRenderKey(
            source: source ?? " ",
            comparison: comparison,
            theme: theme,
            whitespace: preferences.showWhitespace,
            highlightLevel: preferences.highlightLevel,
            inlineColor: inlineColor,
            emphasis: emphasis,
            fontName: preferences.fontName,
            fontSize: contentSize.scaled(preferences.fontSize),
            tabWidth: max(1, preferences.tabWidth),
            lineColumns: nil
        )
        let highlighted = highlightedSource(for: key)
        guard preferences.wrapLines, source != nil else { return highlighted }

        let font = NSFont(name: key.fontName, size: key.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: key.fontSize, weight: .regular)
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        guard spaceWidth.isFinite, spaceWidth > 0 else { return highlighted }
        let availableWidth = paneWidth.isFinite ? max(0, paneWidth - contentSize.scaled(gutterWidth + 20)) : 0
        var wrappingKey = key
        wrappingKey.lineColumns = max(8, Int(min(availableWidth / spaceWidth, CGFloat(Int.max / 4)).rounded(.down)) - 2)
        if let cached = self.cache.object(forKey: CacheKey(wrappingKey)) { return cached.value }

        let wrapped = wrappedSource(highlighted, key: wrappingKey, font: font, spaceWidth: spaceWidth)
        store(wrapped, for: wrappingKey)
        return wrapped

    }

    private func highlightedSource(for key: CodeLineRenderKey) -> AttributedString {

        if let cached = self.cache.object(forKey: CacheKey(key)) { return cached.value }
        let highlighted = SyntaxHighlightService().highlight(
            key.source,
            theme: key.theme,
            whitespace: key.whitespace,
            comparison: key.comparison,
            highlightLevel: key.highlightLevel,
            inlineColor: key.inlineColor,
            emphasis: key.emphasis
        )
        store(highlighted, for: key)
        return highlighted

    }

    private func store(_ value: AttributedString, for key: CodeLineRenderKey) {

        let cost = (value.characters.count + key.source.utf8.count + (key.comparison?.utf8.count ?? 0)) * 64
        self.cache.setObject(RenderedLine(value), forKey: CacheKey(key), cost: cost)

    }

    private func wrappedSource(_ highlighted: AttributedString, key: CodeLineRenderKey, font: NSFont, spaceWidth: CGFloat) -> AttributedString {

        guard let lineColumns = key.lineColumns else { return highlighted }
        let continuationColumns = continuationIndent(for: key.source, lineColumns: lineColumns, tabWidth: key.tabWidth)
        let breaks = wrapBreaks(
            in: key.source,
            lineColumns: lineColumns,
            continuationColumns: continuationColumns,
            font: font,
            spaceWidth: spaceWidth,
            tabWidth: key.tabWidth
        )
        guard !breaks.isEmpty else { return highlighted }
        let styledSource = NSMutableAttributedString(attributedString: NSAttributedString(highlighted))

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

    private func continuationIndent(for source: String, lineColumns: Int, tabWidth: Int) -> Int {

        let leadingWhitespace = source.prefix { $0 == " " || $0 == "\t" }
        var columns = 0

        for character in leadingWhitespace {

            if character == "\t" {
                let tabWidth = max(1, tabWidth)
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
        spaceWidth: CGFloat,
        tabWidth: Int
    ) -> [Int] {

        var breaks: [Int] = []
        var column = 0

        for index in source.indices {

            let character = source[index]
            let width = characterWidth(character, at: column, font: font, spaceWidth: spaceWidth, tabWidth: tabWidth)

            if column > 0 && column + width > lineColumns {

                breaks.append(source.utf16.distance(from: source.startIndex, to: index))
                column = continuationColumns

            }

            column += characterWidth(character, at: column, font: font, spaceWidth: spaceWidth, tabWidth: tabWidth)

        }

        return breaks

    }

    private func characterWidth(_ character: Character, at column: Int, font: NSFont, spaceWidth: CGFloat, tabWidth: Int) -> Int {

        if character == "\t" {

            let tabWidth = max(1, tabWidth)
            return tabWidth - column % tabWidth

        }

        if character.asciiValue != nil {
            return 1
        }

        let measuredWidth = (String(character) as NSString).size(withAttributes: [.font: font]).width
        return max(1, Int((measuredWidth / spaceWidth).rounded()))

    }

    private final class CacheKey: NSObject {

        let value: CodeLineRenderKey

        init(_ value: CodeLineRenderKey) {
            self.value = value
        }

        override var hash: Int { self.value.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            (object as? CacheKey)?.value == self.value
        }

    }

    private final class RenderedLine: NSObject {

        let value: AttributedString

        init(_ value: AttributedString) {
            self.value = value
        }

    }

}
