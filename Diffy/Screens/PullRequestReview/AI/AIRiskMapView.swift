import SwiftUI

struct AIRiskMapView: View {

    let response: RiskMapResponse
    let generation: AIReviewGeneration
    let onOpenFile: (AIReviewGeneration, String) -> Void
    @Binding var selectedRiskID: String?
    @Environment(\.diffyTheme) private var theme

    private var selectedRisk: RiskItem? {
        self.response.risks.first { $0.id == self.selectedRiskID } ?? self.response.risks.first
    }

    var body: some View {

        HStack(spacing: 0) {

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    introduction()
                    if self.response.risks.isEmpty {
                        DiffyEmptyState(
                            symbol: "checkmark.shield",
                            title: "No Supported Risks Identified",
                            message: "The supplied PR context did not support a specific risk to flag. Review the changed files directly."
                        )
                        .frame(height: 240)
                    } else {
                        ForEach([RiskAttention.high, .medium, .low], id: \.self) { attention in
                            riskGroup(attention)
                        }
                    }

                }
                .padding(24)

            }
            .frame(minWidth: 390, maxWidth: .infinity)
            self.theme.border.frame(width: 1)
            riskInspector()
                .frame(width: 340)

        }

    }

    private func introduction() -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(self.response.title)
                .font(.system(size: 20, weight: .semibold))
            Text(self.response.overview)
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)

    }

    @ViewBuilder
    private func riskGroup(_ attention: RiskAttention) -> some View {

        let risks = self.response.risks.filter { $0.attention == attention }
        if !risks.isEmpty {

            VStack(alignment: .leading, spacing: 8) {

                HStack(spacing: 8) {

                    Circle().fill(attention.color(in: self.theme)).frame(width: 8, height: 8)
                    Text("\(attention.title) Attention")
                        .font(.system(size: 12, weight: .semibold))
                    Text(risks.count.formatted())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)

                }
                .padding(.bottom, 3)
                ForEach(risks) { risk in
                    riskRow(risk)
                }

            }

        }

    }

    private func riskRow(_ risk: RiskItem) -> some View {

        let isSelected = self.selectedRisk?.id == risk.id

        return HStack(alignment: .center, spacing: 8) {

            Button {

                self.selectedRiskID = risk.id
                if let path = risk.files.first {
                    self.onOpenFile(self.generation, path)
                }

            } label: {

                VStack(alignment: .leading, spacing: 6) {

                    Text(risk.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(self.theme.text)
                    Text(risk.whyFlagged)
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(risk.files.count) \(risk.files.count == 1 ? "File" : "Files") · \(risk.confidence.title) Confidence")
                        .font(.system(size: 10))
                        .foregroundStyle(risk.attention.color(in: self.theme))

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(isSelected ? self.theme.selection : self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? self.theme.accent.opacity(0.4) : self.theme.border, lineWidth: 1))

            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Diff For \(risk.attention.title) Attention: \(risk.title)")
            Button {
                self.selectedRiskID = risk.id
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .help("Show Risk Details")
            .accessibilityLabel("Show Details For \(risk.title)")

        }

    }

    @ViewBuilder
    private func riskInspector() -> some View {

        if let risk = self.selectedRisk {

            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    DiffyBadge(title: "\(risk.attention.title) Attention", color: risk.attention.color(in: self.theme))
                    Text(risk.title)
                        .font(.system(size: 17, weight: .semibold))
                    section("Why It Was Flagged", values: [risk.whyFlagged])
                    section("Evidence From The Diff", values: risk.evidence)
                    section("What To Inspect", values: risk.inspect)
                    if !risk.symbols.isEmpty {
                        section("Symbols", values: risk.symbols)
                    }
                    if !risk.files.isEmpty {

                        VStack(alignment: .leading, spacing: 8) {

                            sectionLabel("Open Relevant Diffs")
                            ForEach(risk.files, id: \.self) { path in
                                Button {
                                    self.onOpenFile(self.generation, path)
                                } label: {
                                    Label(path, systemImage: "doc.text.magnifyingglass")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(self.theme.accent)
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

            }
            .background(self.theme.surface)
            .textSelection(.enabled)

        }

    }

    @ViewBuilder
    private func section(_ title: String, values: [String]) -> some View {

        if !values.isEmpty {

            VStack(alignment: .leading, spacing: 8) {

                sectionLabel(title)
                ForEach(values, id: \.self) { value in
                    Text(value).font(.system(size: 12))
                }

            }

        }

    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(self.theme.secondaryText)
    }

}

extension RiskAttention {

    var title: String {

        switch self {

        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"

        }

    }

    func color(in theme: DiffyTheme) -> Color {

        switch self {

        case .high: theme.removed
        case .medium: theme.modified
        case .low: theme.changed

        }

    }

}

extension RiskConfidence {

    var title: String {

        switch self {

        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"

        }

    }

}
