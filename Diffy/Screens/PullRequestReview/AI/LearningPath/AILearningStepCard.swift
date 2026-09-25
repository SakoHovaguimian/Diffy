import SwiftUI

struct AILearningStepCard: View {

    let step: LearningPathStep
    let number: Int
    let steps: [LearningPathStep]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onOpenFile: (String) -> Void
    let onRevealStep: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            header()
            if self.isExpanded {

                self.theme.border.frame(height: 1).padding(.horizontal, 18)
                AILearningStepDetail(
                    step: self.step,
                    steps: self.steps,
                    onOpenFile: self.onOpenFile,
                    onRevealStep: self.onRevealStep
                )
                .padding(20)

            }

        }
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(self.isExpanded ? self.theme.accent.opacity(0.45) : self.theme.border, lineWidth: 1)
                .allowsHitTesting(false)
        }

    }

    private func header() -> some View {

        Button(action: self.onToggle) {

            HStack(alignment: .top, spacing: 14) {

                Text(self.number.formatted())
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(self.isExpanded ? self.theme.accent : self.theme.secondaryText)
                    .frame(width: 34, height: 34)
                    .background(self.isExpanded ? self.theme.selection : self.theme.background, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 6) {

                    Text(self.step.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(self.theme.text)
                    Text(self.step.explanation)
                        .font(.system(size: 12))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineSpacing(3)

                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: self.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(self.isExpanded ? self.theme.accent : self.theme.secondaryText)
                    .frame(width: 20, height: 34)
                    .accessibilityHidden(true)

            }
            .padding(18)
            .contentShape(Rectangle())

        }
        .buttonStyle(.borderless)
        .help(self.isExpanded ? "Collapse Step" : "Expand Step")
        .accessibilityLabel("Step \(self.number): \(self.step.title). \(self.step.explanation)")
        .accessibilityValue(self.isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(self.isExpanded ? "Hide this explanation." : "Show the explanation, examples, and files.")

    }

}
