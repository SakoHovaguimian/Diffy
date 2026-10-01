import SwiftUI

/// Native, selectable Markdown. Teaching links are restricted; GitHub discussion can opt in to web links.
struct DiffyMarkdownView: View {

    let markdown: String
    var codeLinks: [String: URL] = [:]
    var allowedLinks: Set<URL> = []
    var opensWebLinks = false
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

            if self.allowedLinks.contains(url) {

                self.onOpenLink(url)
                return .handled

            }

            return allowsWebLink(url) ? .systemAction(url) : .discarded

        })

    }

    @ViewBuilder
    private func blockView(_ block: DiffyMarkdownBlock) -> some View {

        if block.isCode {

            ScrollView(.horizontal) {
                Text(block.text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(self.theme.text)
                    .fixedSize(horizontal: true, vertical: true)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .background(self.theme.background, in: RoundedRectangle(cornerRadius: 6))

        } else {

            HStack(alignment: .top, spacing: 10) {

                if block.isQuote {
                    self.theme.accent.opacity(0.5).frame(width: 2)
                }
                if let isCompleted = block.taskCompletion {
                    Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isCompleted ? self.theme.added : self.theme.secondaryText)
                        .frame(width: 16)
                        .padding(.top, 3)
                        .accessibilityLabel(isCompleted ? "Completed task" : "Incomplete task")
                } else if let marker = block.listMarker {
                    Text(marker)
                        .foregroundStyle(self.theme.secondaryText)
                        .frame(minWidth: 16, alignment: .trailing)
                }
                Text(styledText(block.contentText))
                    .font(blockFont(headingLevel: block.headingLevel))
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

            if let link = run.link, !self.allowedLinks.contains(link) && !allowsWebLink(link) {
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

            if let link = result[run.range].link, self.allowedLinks.contains(link) || allowsWebLink(link) {

                result[run.range].foregroundColor = self.theme.accent
                result[run.range].underlineStyle = .single

            }

        }

        return result

    }

    private func allowsWebLink(_ url: URL) -> Bool {

        guard self.opensWebLinks, let scheme = url.scheme?.lowercased(), url.host?.isEmpty == false else { return false }
        return scheme == "https" || scheme == "http"

    }

    private func blockFont(headingLevel: Int?) -> Font {

        switch headingLevel {

        case 1: .system(size: 21, weight: .semibold)
        case 2: .system(size: 17, weight: .semibold)
        case .some: .system(size: 14, weight: .semibold)
        case .none: .system(size: 13)

        }

    }

}
