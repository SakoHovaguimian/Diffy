import SwiftUI

struct AILearningPathView: View {

    let response: LearningPathResponse
    let generation: AIReviewGeneration
    let onOpenFile: (AIReviewGeneration, String) -> Void
    @Binding var selectedStepID: String?
    @Environment(\.diffyTheme) private var theme

    private var selectedStep: LearningPathStep? {
        self.response.steps.first { $0.id == self.selectedStepID } ?? self.response.steps.first
    }

    var body: some View {

        HStack(spacing: 0) {

            ScrollView {

                VStack(alignment: .leading, spacing: 0) {

                    introduction()
                    ForEach(Array(self.response.steps.enumerated()), id: \.element.id) { index, step in
                        stepRow(step, number: index + 1, hasFollowingStep: index < self.response.steps.count - 1)
                    }

                }
                .padding(24)

            }
            .frame(minWidth: 350, maxWidth: .infinity)
            self.theme.border.frame(width: 1)
            stepInspector()
                .frame(width: 330)

        }

    }

    private func introduction() -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(self.response.title)
                .font(.system(size: 20, weight: .semibold))
                .textSelection(.enabled)
            Text(self.response.overview)
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .textSelection(.enabled)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 22)

    }

    private func stepRow(_ step: LearningPathStep, number: Int, hasFollowingStep: Bool) -> some View {

        let isSelected = self.selectedStep?.id == step.id

        return HStack(alignment: .top, spacing: 14) {

            VStack(spacing: 0) {

                Text(number.formatted())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? self.theme.accent : self.theme.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? self.theme.selection : self.theme.surface, in: Circle())
                    .overlay(Circle().stroke(self.theme.border, lineWidth: 1))
                if hasFollowingStep {
                    self.theme.border.frame(width: 1).frame(maxHeight: .infinity)
                }

            }
            Button {
                self.selectedStepID = step.id
            } label: {

                VStack(alignment: .leading, spacing: 7) {

                    Text(step.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(self.theme.text)
                    Text(step.explanation)
                        .font(.system(size: 12))
                        .foregroundStyle(self.theme.secondaryText)
                        .multilineTextAlignment(.leading)
                    if !step.relevantFiles.isEmpty {

                        Text("\(step.relevantFiles.count) Relevant \(step.relevantFiles.count == 1 ? "File" : "Files")")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(self.theme.accent)

                    }

                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? self.theme.selection : self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? self.theme.accent.opacity(0.4) : self.theme.border, lineWidth: 1))

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Step \(number): \(step.title)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])

        }
        .frame(minHeight: 100)

    }

    @ViewBuilder
    private func stepInspector() -> some View {

        if let step = self.selectedStep {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    Text(step.title)
                        .font(.system(size: 16, weight: .semibold))
                        .textSelection(.enabled)
                    inspectorSection("Why It Matters") {
                        Text(step.whyItMatters)
                    }
                    if !step.dependsOn.isEmpty {
                        inspectorSection("Builds On") {

                            ForEach(step.dependsOn, id: \.self) { identifier in
                                Button {
                                    self.selectedStepID = identifier
                                } label: {
                                    Text(self.response.steps.first { $0.id == identifier }?.title ?? identifier)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(self.theme.accent)
                            }

                        }
                    }
                    if !step.relevantSymbols.isEmpty {
                        inspectorSection("Relevant Symbols") {

                            ForEach(step.relevantSymbols, id: \.self) { symbol in
                                Text(symbol).font(.system(size: 11, design: .monospaced))
                            }

                        }
                    }
                    fileSection("Open These Files", files: step.suggestedFiles)
                    fileSection("Other Relevant Files", files: step.relevantFiles.filter { !step.suggestedFiles.contains($0) })

                }
                .padding(20)

            }
            .background(self.theme.surface)

        }

    }

    @ViewBuilder
    private func inspectorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(self.theme.secondaryText)
            content()
                .font(.system(size: 12))
                .textSelection(.enabled)

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    @ViewBuilder
    private func fileSection(_ title: String, files: [String]) -> some View {

        if !files.isEmpty {
            inspectorSection(title) {

                ForEach(files, id: \.self) { path in
                    Button {
                        self.onOpenFile(self.generation, path)
                    } label: {
                        Label(path, systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(self.theme.accent)
                    .help("Open The Diff For \(path)")
                }

            }
        }

    }

}
