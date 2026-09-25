import SwiftUI

struct AILearningPathView: View {

    let response: LearningPathResponse
    let generation: AIReviewGeneration
    let onOpenFile: (AIReviewGeneration, String) -> Void
    @Binding var expandedStepIDs: Set<String>
    @Environment(\.diffyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var allExpanded: Bool {
        Set(self.response.steps.map(\.id)).isSubset(of: self.expandedStepIDs)
    }

    var body: some View {

        ScrollViewReader { proxy in
            ScrollView {

                LazyVStack(alignment: .leading, spacing: 0) {

                    introduction()
                    ForEach(Array(self.response.steps.enumerated()), id: \.element.id) { index, step in

                        AILearningStepCard(
                            step: step,
                            number: index + 1,
                            steps: self.response.steps,
                            isExpanded: self.expandedStepIDs.contains(step.id),
                            onToggle: { toggleStep(step.id) },
                            onOpenFile: { self.onOpenFile(self.generation, $0) },
                            onRevealStep: { identifier in
                                revealStep(identifier, proxy: proxy)
                            }
                        )
                        .id(step.id)
                        if index < self.response.steps.count - 1 {
                            self.theme.border.frame(width: 1, height: 16)
                                .padding(.leading, 35)
                                .accessibilityHidden(true)
                        }

                    }

                }
                .frame(maxWidth: 860)
                .padding(24)
                .frame(maxWidth: .infinity)

            }
        }

    }

    private func introduction() -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Label("A Guided Walkthrough", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.accent)
            Text(self.response.title)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(self.theme.text)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .accessibilityAddTraits(.isHeader)
            Text(self.response.overview)
                .font(.system(size: 13))
                .foregroundStyle(self.theme.secondaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            HStack {

                Text("\(self.response.steps.count) \(self.response.steps.count == 1 ? "Step" : "Steps")")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer(minLength: 12)
                Button(self.allExpanded ? "Collapse All" : "Expand All") {
                    withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        self.expandedStepIDs = self.allExpanded ? [] : Set(self.response.steps.map(\.id))
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.accent)

            }
            .padding(.top, 10)

        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private func toggleStep(_ identifier: String) {

        withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.2)) {

            if self.expandedStepIDs.contains(identifier) {
                self.expandedStepIDs.remove(identifier)
            } else {
                self.expandedStepIDs.insert(identifier)
            }

        }

    }

    private func revealStep(_ identifier: String, proxy: ScrollViewProxy) {

        withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.2)) {

            self.expandedStepIDs.insert(identifier)
            proxy.scrollTo(identifier, anchor: .top)

        }

    }

}
