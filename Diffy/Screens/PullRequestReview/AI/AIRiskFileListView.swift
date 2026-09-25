import SwiftUI

struct AIRiskFileListView: View {

    let assessments: [RiskFileAssessment]?
    let generation: AIReviewGeneration
    let selectedPath: String?
    @Binding var filter: RiskAttention?
    let select: (String) -> Void
    let openDiff: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    private var orderedFiles: [RiskFileAssessment] {

        (self.assessments ?? [])
            .filter { self.filter == nil || $0.attention == self.filter }
            .sorted {
                if $0.attention != $1.attention { return $0.attention.sortOrder < $1.attention.sortOrder }
                return $0.path.localizedStandardCompare($1.path) == .orderedAscending
            }

    }

    private var fileMetadata: [String: AIFileSnapshot] {
        Dictionary(uniqueKeysWithValues: self.generation.context.files.map { ($0.filename, $0) })
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .top, spacing: 12) {

                Image(systemName: "doc.text")
                    .font(.system(size: 18))
                    .foregroundStyle(self.theme.accent)
                VStack(alignment: .leading, spacing: 4) {

                    Text("Files by Risk Level")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Every changed file in the analyzed diff, ordered by review attention.")
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.secondaryText)

                }

            }
            .padding(14)

            if let assessments = self.assessments {

                HStack(spacing: 6) {

                    filterButton("All", attention: nil, count: assessments.count)
                    filterButton("High", attention: .high, count: assessments.filter { $0.attention == .high }.count)
                    filterButton("Medium", attention: .medium, count: assessments.filter { $0.attention == .medium }.count)
                    filterButton("Low", attention: .low, count: assessments.filter { $0.attention == .low }.count)

                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                self.theme.border.frame(height: 1)

                let metadata = self.fileMetadata
                LazyVStack(spacing: 0) {

                    ForEach(self.orderedFiles) { assessment in
                        fileRow(assessment, metadata: metadata[assessment.path])
                        self.theme.border.opacity(0.6).frame(height: 1)
                    }

                }

            } else {

                DiffyStatusBanner(message: "This saved Risk Map predates per-file analysis. Regenerate it to see every file by risk level.")
                    .padding(14)

            }

        }
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(self.theme.border, lineWidth: 1))

    }

    private func filterButton(_ title: String, attention: RiskAttention?, count: Int) -> some View {

        Button {
            self.filter = attention
            let first = (self.assessments ?? [])
                .filter { attention == nil || $0.attention == attention }
                .sorted {
                    if $0.attention != $1.attention { return $0.attention.sortOrder < $1.attention.sortOrder }
                    return $0.path.localizedStandardCompare($1.path) == .orderedAscending
                }
                .first
            if let first { self.select(first.path) }
        } label: {
            Text("\(title) \(count)")
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(self.filter == attention ? self.theme.selection : self.theme.elevated, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(self.filter == attention ? .isSelected : [])

    }

    private func fileRow(_ assessment: RiskFileAssessment, metadata: AIFileSnapshot?) -> some View {

        let isSelected = self.selectedPath == assessment.path

        return HStack(spacing: 8) {

            Button {
                self.select(assessment.path)
            } label: {

                HStack(spacing: 9) {

                    Image(systemName: "doc.text")
                        .foregroundStyle(self.theme.accent)
                        .frame(width: 16)
                    Text(assessment.path)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DiffyBadge(title: assessment.attention.title, color: assessment.attention.color(in: self.theme), size: .small)
                    Text(assessment.factors.prefix(2).joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: 145, alignment: .leading)
                    if let metadata {
                        Text("+\(metadata.additions) −\(metadata.deletions)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(self.theme.secondaryText)
                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            Button {
                self.openDiff(assessment.path)
            } label: {
                Image(systemName: "arrow.up.right.square")
            }
            .buttonStyle(.plain)
            .help("Open Diff For \(assessment.path)")
            .accessibilityLabel("Open Diff For \(assessment.path)")

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? self.theme.selection : Color.clear)

    }

}
