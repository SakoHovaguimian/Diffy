import SwiftUI

struct PullRequestRowStatistics: View {

    let summary: PullRequestSummary?
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        HStack(alignment: .top, spacing: self.contentSize.scaled(12)) {

            count(self.summary?.changedFileCount, title: "Files changed", symbol: "doc")
            separator()
            count(self.summary?.commentCount, title: "Comments", symbol: "text.bubble")
            separator()
            lineChanges()

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private func count(_ value: Int?, title: String, symbol: String) -> some View {

        HStack(alignment: .top, spacing: self.contentSize.scaled(7)) {

            Image(systemName: symbol)
                .font(self.contentSize.font(size: 15))
                .foregroundStyle(self.theme.secondaryText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: self.contentSize.scaled(4)) {

                Text(value?.formatted() ?? "—")
                    .font(self.contentSize.font(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(self.theme.countColor(for: value ?? 0, activeColor: self.theme.text))

                Text(title)
                    .font(self.contentSize.font(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                    .lineLimit(2)

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.map { "\($0) \(title)" } ?? "\(title) unavailable")

    }

    private func lineChanges() -> some View {

        VStack(alignment: .leading, spacing: self.contentSize.scaled(4)) {

            if let counts = self.summary?.lineCounts {

                ViewThatFits(in: .horizontal) {

                    HStack(spacing: self.contentSize.scaled(8)) {

                        changeCounts(counts)

                    }
                    .fixedSize(horizontal: true, vertical: false)

                    VStack(alignment: .leading, spacing: self.contentSize.scaled(3)) {
                        changeCounts(counts)
                    }

                }
                .font(self.contentSize.font(size: 12, weight: .semibold))
                .monospacedDigit()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(counts.additions) additions, \(counts.deletions) deletions")

            } else {

                Text("—")
                    .font(self.contentSize.font(size: 12, weight: .semibold))
                    .foregroundStyle(self.theme.secondaryText)
                    .accessibilityLabel("Line changes unavailable")

            }

            Text("Line changes")
                .font(self.contentSize.font(size: 10))
                .foregroundStyle(self.theme.secondaryText)
                .lineLimit(1)

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    @ViewBuilder
    private func changeCounts(_ counts: DiffLineCounts) -> some View {

        Text("+\(counts.additions.formatted())")
            .foregroundStyle(self.theme.countColor(for: counts.additions, activeColor: self.theme.added))
            .lineLimit(1)

        Text("−\(counts.deletions.formatted())")
            .foregroundStyle(self.theme.countColor(for: counts.deletions, activeColor: self.theme.removed))
            .lineLimit(1)

    }

    private func separator() -> some View {
        self.theme.border.frame(width: 1, height: self.contentSize.scaled(33))
    }

}
