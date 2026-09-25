import SwiftUI

struct SyntaxHighlightService {

    func highlight(
        _ source: String,
        theme: DiffyTheme,
        whitespace: Bool,
        comparison: String?,
        highlightLevel: String,
        inlineColor: Color,
        emphasis: String?
    ) -> AttributedString {

        var value = AttributedString(source)
        value.foregroundColor = theme.text

        apply("\\b(import|final|class|struct|let|var|private|func|return|self|init|try|await|async|throw|if|else|guard|nil)\\b", color: theme.keyword, source: source, value: &value)
        apply("\\b[A-Z][A-Za-z0-9_]*\\b", color: theme.type, source: source, value: &value)
        apply("\"[^\"]*\"", color: theme.string, source: source, value: &value)
        apply("//.*$", color: theme.comment, source: source, value: &value)

        if highlightLevel != "Line", let comparison {

            for range in changedRanges(in: source, comparedWith: comparison, level: highlightLevel) {

                guard let sourceRange = Range(range, in: source),
                      let attributedRange = Range(sourceRange, in: value) else {
                    continue
                }

                value[attributedRange].backgroundColor = inlineColor.opacity(theme.isDark ? 0.36 : 0.22)

            }

        } else if highlightLevel != "Line", let emphasis, let range = value.range(of: emphasis) {
            value[range].backgroundColor = inlineColor.opacity(theme.isDark ? 0.36 : 0.22)
        }

        if whitespace {
            value = visualizeWhitespace(value, theme: theme)
        }

        return value

    }

    func changedRanges(in source: String, comparedWith comparison: String, level: String) -> [NSRange] {

        let sourceTokens = tokens(in: source, level: level)
        let comparisonTokens = tokens(in: comparison, level: level)

        if sourceTokens.count > 500 || comparisonTokens.count > 500 {
            return broadChangeRange(in: sourceTokens, comparedWith: comparisonTokens)
        }

        let difference = sourceTokens.map(\.text).difference(from: comparisonTokens.map(\.text))
        let changed = difference.compactMap { change -> NSRange? in

            guard case let .insert(offset, _, _) = change else {
                return nil
            }

            return sourceTokens[offset].range

        }

        return mergedRanges(changed)

    }

    private func tokens(in source: String, level: String) -> [InlineToken] {

        if level == "Character" {

            return source.indices.map { index in

                let next = source.index(after: index)
                return InlineToken(
                    text: String(source[index..<next]),
                    range: NSRange(index..<next, in: source)
                )

            }

        }

        guard let expression = try? NSRegularExpression(pattern: "\\w+|\\s+|[^\\w\\s]") else {
            return []
        }

        let fullRange = NSRange(source.startIndex..., in: source)
        let text = source as NSString

        return expression.matches(in: source, range: fullRange).map { match in
            InlineToken(text: text.substring(with: match.range), range: match.range)
        }

    }

    private func broadChangeRange(in source: [InlineToken], comparedWith comparison: [InlineToken]) -> [NSRange] {

        var prefix = 0

        while prefix < min(source.count, comparison.count), source[prefix].text == comparison[prefix].text {
            prefix += 1
        }

        var sourceEnd = source.count
        var comparisonEnd = comparison.count

        while sourceEnd > prefix, comparisonEnd > prefix,
              source[sourceEnd - 1].text == comparison[comparisonEnd - 1].text {

            sourceEnd -= 1
            comparisonEnd -= 1

        }

        guard sourceEnd > prefix else {
            return []
        }

        let first = source[prefix].range
        let last = source[sourceEnd - 1].range
        return [NSRange(location: first.location, length: NSMaxRange(last) - first.location)]

    }

    private func mergedRanges(_ ranges: [NSRange]) -> [NSRange] {

        var merged: [NSRange] = []

        for range in ranges.sorted(by: { $0.location < $1.location }) {

            if let previous = merged.last, NSMaxRange(previous) >= range.location {

                merged[merged.count - 1] = NSRange(
                    location: previous.location,
                    length: max(NSMaxRange(previous), NSMaxRange(range)) - previous.location
                )

            } else {
                merged.append(range)
            }

        }

        return merged

    }

    private func apply(_ pattern: String, color: Color, source: String, value: inout AttributedString) {

        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return
        }

        let range = NSRange(source.startIndex..., in: source)

        for match in expression.matches(in: source, range: range) {

            guard let sourceRange = Range(match.range, in: source),
                  let attributedRange = Range(sourceRange, in: value) else {
                continue
            }

            value[attributedRange].foregroundColor = color

        }

    }

    private func visualizeWhitespace(_ source: AttributedString, theme: DiffyTheme) -> AttributedString {

        var result = AttributedString()

        for run in source.runs {

            for character in source[run.range].characters {

                var piece = AttributedString(character == " " ? "·" : String(character))
                piece.mergeAttributes(run.attributes)

                if character == " " {
                    piece.foregroundColor = theme.comment.opacity(0.5)
                }

                result.append(piece)

            }

        }

        return result

    }

    private struct InlineToken {
        let text: String
        let range: NSRange
    }

}
