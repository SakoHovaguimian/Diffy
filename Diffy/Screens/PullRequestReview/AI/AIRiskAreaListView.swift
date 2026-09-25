import SwiftUI

struct AIRiskAreaListView: View {

    let risks: [RiskItem]
    let selectedID: String?
    let select: (String) -> Void
    let openDiff: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {

                Text("Review Areas")
                    .font(.system(size: 15, weight: .semibold))
                Text("Select an area to inspect its evidence and review guidance.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }

            if self.risks.isEmpty {
                DiffyEmptyState(
                    symbol: "checkmark.shield",
                    title: "No Specific Review Areas",
                    message: "The supplied diff did not support a separate cross-file risk to flag. Review the file assessments above."
                )
                .frame(height: 180)
            } else {

                ForEach([RiskAttention.high, .medium, .low], id: \.self) { attention in
                    riskGroup(attention)
                }

            }

        }

    }

    @ViewBuilder
    private func riskGroup(_ attention: RiskAttention) -> some View {

        let items = self.risks.filter { $0.attention == attention }
        if !items.isEmpty {

            VStack(alignment: .leading, spacing: 8) {

                HStack(spacing: 7) {

                    Circle().fill(attention.color(in: self.theme)).frame(width: 8, height: 8)
                    Text("\(attention.title) Attention")
                        .font(.system(size: 11, weight: .semibold))
                    Text(items.count.formatted())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)

                }

                ForEach(items) { risk in
                    riskRow(risk)
                }

            }

        }

    }

    private func riskRow(_ risk: RiskItem) -> some View {

        let isSelected = self.selectedID == risk.id

        return HStack(spacing: 8) {

            Button {
                self.select(risk.id)
            } label: {

                VStack(alignment: .leading, spacing: 6) {

                    HStack(spacing: 8) {

                        Text(risk.title)
                            .font(.system(size: 12, weight: .semibold))
                        Spacer(minLength: 0)
                        DiffyBadge(title: risk.attention.title, color: risk.attention.color(in: self.theme), size: .small)

                    }
                    Text(risk.whyFlagged)
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(2)
                    Text("\(risk.files.count) \(risk.files.count == 1 ? "File" : "Files") · \(risk.confidence.title) Confidence")
                        .font(.system(size: 10))
                        .foregroundStyle(self.theme.secondaryText)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            if let path = risk.files.first {

                Button {
                    self.openDiff(path)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.plain)
                .help("Open Diff For \(path)")
                .accessibilityLabel("Open Diff For \(path)")

            }

        }
        .padding(12)
        .background(isSelected ? self.theme.selection : self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? self.theme.accent.opacity(0.45) : self.theme.border, lineWidth: 1))

    }

}
