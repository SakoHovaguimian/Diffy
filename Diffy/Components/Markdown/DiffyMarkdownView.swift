import SwiftUI

/// Native, selectable teaching text. Only explicitly supplied destinations are interactive.
struct DiffyMarkdownView: View {

    let markdown: String
    var codeLinks: [String: URL] = [:]
    var allowedLinks: Set<URL> = []
    var onOpenLink: (URL) -> Void = { _ in }
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {
            ForEach(DiffyMarkdownBlock.parse(self.markdown)) { block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(self.theme.accent)
        .environment(\.openURL, OpenURLAction { url in

            guard self.allowedLinks.contains(url) else { return .discarded }
            self.onOpenLink(url)
            return .handled

        })

    }

    @ViewBuilder
    private func blockView(_ block: DiffyMarkdownBlock) -> some View {

        if block.isCode {

            ScrollView(.horizontal) {
                Text(block.text)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(self.theme.background, in: RoundedRectangle(cornerRadius: 6))

        } else {

            HStack(alignment: .top, spacing: 10) {

                if block.isQuote {
                    self.theme.accent.opacity(0.5).frame(width: 2)
                }
                if let marker = block.listMarker {
                    Text(marker)
                        .foregroundStyle(self.theme.secondaryText)
                        .frame(minWidth: 16, alignment: .trailing)
                }
                Text(styledText(block.text))
                    .font(block.headingLevel == nil ? .system(size: 13) : .system(size: 14, weight: .semibold))
                    .foregroundStyle(self.theme.text)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(block.headingLevel == nil ? [] : .isHeader)

            }
            .font(.system(size: 13))
            .padding(.top, block.headingLevel == nil ? 0 : 4)

        }

    }

    private func styledText(_ text: AttributedString) -> AttributedString {

        var result = text
        for run in Array(result.runs) {

            if let link = run.link, !self.allowedLinks.contains(link) {
                result[run.range].link = nil
            }

            if run.inlinePresentationIntent?.contains(.code) == true {

                let label = String(result[run.range].characters)
                result[run.range].font = .system(size: 12, weight: .medium, design: .monospaced)
                result[run.range].backgroundColor = self.theme.elevated
                if let link = self.codeLinks[label], self.allowedLinks.contains(link) {
                    result[run.range].link = link
                }

            }

            if let link = result[run.range].link, self.allowedLinks.contains(link) {

                result[run.range].foregroundColor = self.theme.accent
                result[run.range].underlineStyle = .single

            }

        }

        return result

    }

}
