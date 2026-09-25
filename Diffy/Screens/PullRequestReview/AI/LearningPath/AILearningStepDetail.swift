import SwiftUI

struct AILearningStepDetail: View {

    let step: LearningPathStep
    let steps: [LearningPathStep]
    let onOpenFile: (String) -> Void
    let onRevealStep: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    private var nextStep: LearningPathStep? {

        guard let index = self.steps.firstIndex(where: { $0.id == self.step.id }),
              self.steps.indices.contains(index + 1) else { return nil }
        return self.steps[index + 1]

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 22) {

            breakdown()
            if !self.step.examples.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(self.step.examples) { example in
                        AILearningExampleView(example: example, onOpenFile: self.onOpenFile)
                    }
                }
            }
            takeaway()
            files()
            navigation()

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    @ViewBuilder
    private func breakdown() -> some View {

        if self.step.breakdownDescriptions.isEmpty {

            Text("This saved path has a brief overview. Generate a new path for a full walkthrough with examples.")
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .textSelection(.enabled)
            if !self.step.relevantSymbols.isEmpty {
                Text(self.step.relevantSymbols.joined(separator: " · "))
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
            }

        } else {

            DiffyMarkdownView(
                markdown: self.step.breakdownDescriptions,
                codeLinks: self.step.markdownCodeLinks,
                allowedLinks: Set(self.step.codeReferences.compactMap(\.url)),
                onOpenLink: { url in
                    if let path = self.step.filePath(for: url) {
                        self.onOpenFile(path)
                    }
                }
            )

        }

    }

    private func takeaway() -> some View {

        HStack(alignment: .top, spacing: 10) {

            Image(systemName: "lightbulb")
                .font(.system(size: 13))
                .foregroundStyle(self.theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {

                Text("Why It Matters")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(self.theme.secondaryText)
                Text(self.step.whyItMatters)
                    .font(.system(size: 13))
                    .foregroundStyle(self.theme.text)
                    .lineSpacing(4)
                    .textSelection(.enabled)

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private func files() -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("Open The Files")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(self.theme.secondaryText)
            ForEach(self.step.orderedFiles, id: \.self) { path in
                AILearningFileButton(path: path) { self.onOpenFile(path) }
            }

        }

    }

    @ViewBuilder
    private func navigation() -> some View {

        if !self.step.dependsOn.isEmpty || self.nextStep != nil {

            VStack(alignment: .leading, spacing: 12) {

                self.theme.border.frame(height: 1)
                ForEach(self.steps.filter { self.step.dependsOn.contains($0.id) }) { dependency in
                    Button {
                        self.onRevealStep(dependency.id)
                    } label: {
                        Label("Revisit: \(dependency.title)", systemImage: "arrow.turn.up.left")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                }
                if let nextStep = self.nextStep {
                    Button {
                        self.onRevealStep(nextStep.id)
                    } label: {
                        Label("Next: \(nextStep.title)", systemImage: "arrow.down")
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(self.theme.accent)
                }

            }

        }

    }

}
