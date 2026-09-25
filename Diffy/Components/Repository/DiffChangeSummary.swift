import SwiftUI

struct DiffChangeSummary: View {

    let counts: DiffLineCounts
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 7) {

            Text("+\(self.counts.additions.formatted())").foregroundStyle(self.theme.added)
            Text("−\(self.counts.deletions.formatted())").foregroundStyle(self.theme.removed)

            HStack(spacing: 2) {

                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(blockColor(index))
                        .frame(width: 5, height: 8)
                }

            }
            .accessibilityHidden(true)

        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(self.counts.additions) Additions, \(self.counts.deletions) Deletions")

    }

    private func blockColor(_ index: Int) -> Color {

        let total = self.counts.additions + self.counts.deletions
        guard total > 0 else { return self.theme.border }
        let addedBlocks = Int((Double(self.counts.additions) / Double(total) * 5).rounded())
        return index < addedBlocks ? self.theme.added : self.theme.removed

    }

}
