import SwiftUI

struct AIRiskInspectorView: View {

    let file: RiskFileAssessment?
    let risk: RiskItem?
    let generation: AIReviewGeneration
    let openDiff: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            if let risk {
                riskDetails(risk)
            } else if let file {
                fileDetails(file)
            } else {

                DiffyEmptyState(
                    symbol: "hand.point.up.left",
                    title: "Select an Area",
                    message: "Choose a file or review card to inspect its evidence."
                )
                .frame(minHeight: 280)

            }

        }
        .background(self.theme.surface)

    }

    private func fileDetails(_ file: RiskFileAssessment) -> some View {

        let metadata = self.generation.context.files.first { $0.filename == file.path }

        return VStack(alignment: .leading, spacing: 18) {

            HStack {

                Text("FILE RISK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(self.theme.secondaryText)
                Spacer()
                DiffyBadge(title: file.attention.title, color: file.attention.color(in: self.theme), size: .small)

            }
            Text(file.path)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .textSelection(.enabled)
            if let metadata {
                Text("+\(metadata.additions) −\(metadata.deletions) · \(metadata.status.capitalized)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)
            }
            Button("Open Diff") { self.openDiff(file.path) }
                .buttonStyle(.borderedProminent)
            section("Why This File Needs Review", values: [file.summary])
            section("Key Risk Factors", values: file.factors)
            section("Evidence From The Diff", values: file.evidence)
            section("What To Review First", values: file.inspect, numbered: true)
            section("Confidence", values: [file.confidence.title])
            if !file.uncertainty.isEmpty {
                section("Uncertainty", values: [file.uncertainty])
            }

        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private func riskDetails(_ risk: RiskItem) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                Text("REVIEW AREA")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(self.theme.secondaryText)
                Spacer()
                DiffyBadge(title: risk.attention.title, color: risk.attention.color(in: self.theme), size: .small)

            }
            Text(risk.title)
                .font(.system(size: 17, weight: .semibold))
            section("Why It Was Flagged", values: [risk.whyFlagged])
            section("Evidence From The Diff", values: risk.evidence)
            section("What To Review First", values: risk.inspect, numbered: true)
            if !risk.symbols.isEmpty {
                section("Symbols", values: risk.symbols)
            }
            if !risk.files.isEmpty {

                VStack(alignment: .leading, spacing: 8) {

                    sectionLabel("Related Files")
                    ForEach(risk.files, id: \.self) { path in
                        Button {
                            self.openDiff(path)
                        } label: {
                            Label(path, systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(self.theme.accent)
                        .accessibilityLabel("Open Diff For \(path)")
                    }

                }

            }
            section("Confidence", values: [risk.confidence.title])
            if !risk.uncertainty.isEmpty {
                section("Uncertainty", values: [risk.uncertainty])
            }

        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)

    }

    @ViewBuilder
    private func section(_ title: String, values: [String], numbered: Bool = false) -> some View {

        if !values.isEmpty {

            VStack(alignment: .leading, spacing: 8) {

                sectionLabel(title)
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in

                    HStack(alignment: .top, spacing: 8) {

                        if numbered {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .frame(width: 18, height: 18)
                                .background(self.theme.selection, in: Circle())
                        }
                        Text(value)
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }

                }

            }
            .textSelection(.enabled)

        }

    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(self.theme.secondaryText)
    }

}
