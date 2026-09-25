import SwiftUI

struct SyntaxHighlightService {

    func highlight(_ source: String, theme: DiffyTheme, whitespace: Bool, emphasis: String?) -> AttributedString {

        var value = AttributedString(source)
        value.foregroundColor = theme.text

        apply("\\b(import|final|class|struct|let|var|private|func|return|self|init|try|await|async|throw|if|else|guard|nil)\\b", color: theme.keyword, source: source, value: &value)
        apply("\\b[A-Z][A-Za-z0-9_]*\\b", color: theme.type, source: source, value: &value)
        apply("\"[^\"]*\"", color: theme.string, source: source, value: &value)
        apply("//.*$", color: theme.comment, source: source, value: &value)

        if let emphasis, let range = value.range(of: emphasis) {
            value[range].backgroundColor = theme.modified.opacity(0.18)
        }

        if whitespace {
            value = visualizeWhitespace(value, theme: theme)
        }

        return value

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

}
