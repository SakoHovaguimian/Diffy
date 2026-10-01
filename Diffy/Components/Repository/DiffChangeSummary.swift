import SwiftUI

struct DiffChangeSummary: View {

    let counts: DiffLineCounts
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 7) {

            Text("+\(self.counts.additions.formatted())").foregroundStyle(self.theme.countColor(for: self.counts.additions, activeColor: self.theme.added))
            Text("−\(self.counts.deletions.formatted())").foregroundStyle(self.theme.countColor(for: self.counts.deletions, activeColor: self.theme.removed))

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
        let addedBlocks = addedBlockCount(total: total)
        return index < addedBlocks ? self.theme.added : self.theme.removed

    }

    private func addedBlockCount(total: Int) -> Int {

        guard self.counts.additions > 0 else { return 0 }
        guard self.counts.deletions > 0 else { return 5 }

        let proportionalCount = Int((Double(self.counts.additions) / Double(total) * 5).rounded())
        return min(4, max(1, proportionalCount))

    }

}
