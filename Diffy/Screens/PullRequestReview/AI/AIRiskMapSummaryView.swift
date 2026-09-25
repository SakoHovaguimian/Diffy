import SwiftUI

struct AIRiskMapSummaryView: View {

    let response: RiskMapResponse
    let totalFiles: Int
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .top, spacing: 12) {

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 24))
                    .foregroundStyle(self.theme.accent)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 5) {

                    Text(self.response.title)
                        .font(.system(size: 20, weight: .semibold))
                    Text(self.response.overview)
                        .font(.system(size: 12))
                        .foregroundStyle(self.theme.secondaryText)

                }

            }
            .textSelection(.enabled)

            if let blastRadius = self.response.blastRadius, !blastRadius.isEmpty {

                VStack(alignment: .leading, spacing: 5) {

                    Text("BLAST RADIUS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(self.theme.secondaryText)
                    Text(blastRadius)
                        .font(.system(size: 12))
                        .textSelection(.enabled)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(self.theme.selection, in: RoundedRectangle(cornerRadius: 8))

            }

            if let assessments = self.response.fileAssessments {

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {

                    metric("High Attention", value: "\(assessments.filter { $0.attention == .high }.count)", detail: "Files to review first", color: self.theme.removed)
                    metric("Medium Attention", value: "\(assessments.filter { $0.attention == .medium }.count)", detail: "Files needing review", color: self.theme.modified)
                    metric("Files Assessed", value: "\(assessments.count)/\(self.totalFiles)", detail: "Changed files in the diff", color: self.theme.accent)
                    metric("Blast Radius", value: self.response.blastRadiusLevel?.title ?? "Unrated", detail: "Cross-file impact", color: self.response.blastRadiusLevel?.color(in: self.theme) ?? self.theme.secondaryText)

                }

            }

        }

    }

    private func metric(_ title: String, value: String, detail: String, color: Color) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 23, weight: .semibold))
                .monospacedDigit()
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(self.theme.secondaryText)

        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(12)
        .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border, lineWidth: 1))

    }

}
