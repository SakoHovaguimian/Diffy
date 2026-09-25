import SwiftUI

struct ReviewExportScreen: View {

    let annotations: [CodeAnnotation]
    let scope: String
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme
    @State private var openOnly = false
    @State private var feedback = ""

    private var exportAnnotations: [CodeAnnotation] {
        self.annotations.filter { !self.openOnly || !$0.isResolved }
    }

    private var markdown: String {
        self.review.export(self.exportAnnotations, scope: self.scope)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                VStack(alignment: .leading, spacing: 5) {

                    Text("Your Review, Ready To Share.")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Code, context, and your exact words. Formatted for an LLM.")
                        .font(.system(size: 12))
                        .foregroundStyle(self.theme.secondaryText)

                }

                Spacer()
                DiffyIconButton(symbol: "xmark", label: "Close Export") { self.dismiss() }

            }

            HStack {

                DiffyBadge(title: "\(self.exportAnnotations.count) ANNOTATIONS", color: self.theme.accent)
                Text(self.scope).font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
                Spacer()
                Toggle("Open Notes Only", isOn: self.$openOnly).font(.system(size: 11))

            }

            ScrollView([.vertical, .horizontal]) {

                Text(self.markdown)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)

            }
            .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border))

            HStack {

                Text(self.feedback.isEmpty ? "Nothing is sent automatically." : self.feedback)
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer()

                Button("Save Markdown…") {
                    ExportController.saveMarkdown(self.markdown) { self.feedback = $0 }
                }

                Button {
                    self.feedback = ExportController.copy(self.markdown) ? "Copied all \(self.exportAnnotations.count) annotations." : "Could not access the clipboard."
                } label: {
                    Label("Copy For LLM", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)

            }

        }
        .padding(28)
        .frame(width: 780, height: 640)
        .background(self.theme.background)

    }

}

#Preview {

    ReviewExportScreen(
        annotations: [MockPreviewFixtures.annotation],
        scope: "Rune · working tree"
    )
    .withMockPreviews()

}
