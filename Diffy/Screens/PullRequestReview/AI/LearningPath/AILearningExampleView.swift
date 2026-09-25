import SwiftUI

struct AILearningExampleView: View {

    let example: LearningPathExample
    let onOpenFile: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    private let sourceURL = URL(string: "diffy://learning-example/source")

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline, spacing: 12) {

                Text(self.example.title)
                    .font(.system(size: 13, weight: .semibold))
                    .textSelection(.enabled)
                Spacer(minLength: 8)
                Text(self.example.kind.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)

            }
            codeSurface()
            Text(self.example.explanation)
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

        }

    }

    private func codeSurface() -> some View {

        VStack(spacing: 0) {

            HStack(spacing: 12) {

                AILearningFileButton(path: self.example.filePath) {
                    self.onOpenFile(self.example.filePath)
                }
                if !self.example.language.isEmpty {
                    Text(self.example.language.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)
                }
                Button {
                    ExportController.copy(self.example.code)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy Code")
                .accessibilityLabel("Copy Code")

            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            self.theme.border.frame(height: 1)
            ScrollView(.horizontal) {

                Text(highlightedCode())
                    .font(.system(size: 12, design: .monospaced))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(14)
                    .help("Open The Diff For \(self.example.filePath)")
                    .accessibilityHint("Activate the code to open its file.")

            }

        }
        .background(self.theme.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border, lineWidth: 1))
        .tint(self.theme.accent)
        .environment(\.openURL, OpenURLAction { url in

            guard url == self.sourceURL else { return .discarded }
            self.onOpenFile(self.example.filePath)
            return .handled

        })

    }

    private func highlightedCode() -> AttributedString {

        var result = AttributedString()
        let lines = self.example.code.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {

            if index > 0 { result.append(AttributedString("\n")) }
            result.append(SyntaxHighlightService().highlight(
                line,
                theme: self.theme,
                whitespace: false,
                comparison: nil,
                highlightLevel: "Line",
                inlineColor: self.theme.accent,
                emphasis: nil
            ))

        }

        result.link = self.sourceURL
        return result

    }

}
