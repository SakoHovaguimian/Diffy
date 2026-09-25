import SwiftUI

struct OverviewProjectRow: View {

    let change: OverviewProjectChange
    let bucket: Bucket?
    let open: () -> Void
    @Environment(\.diffyTheme) private var theme

    private var tint: Color {
        self.bucket.map { Color(hex: $0.accentHex) } ?? self.theme.accent
    }

    private var accessibilitySummary: String {

        let counts = self.change.lineCounts.map { ", plus \($0.additions) lines, minus \($0.deletions) lines" } ?? ", line counts unavailable"
        let conflicts = self.change.hasConflicts ? ", conflicts" : ""
        return "\(self.change.project.displayName), \(self.change.changedFileCount) changed files\(counts)\(conflicts)"

    }

    var body: some View {

        Button(action: self.open) {

            HStack(alignment: .top, spacing: 13) {

                Image(systemName: self.change.project.symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(self.tint)
                    .frame(width: 42, height: 42)
                    .background(self.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 7) {

                    HStack(spacing: 8) {

                        Text(self.change.project.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(self.theme.secondaryText)

                    }

                    Label(self.change.branchName, systemImage: "arrow.triangle.branch")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 12) {

                        Text("\(self.change.changedFileCount) changed files")
                            .foregroundStyle(self.theme.secondaryText)

                        if let counts = self.change.lineCounts {

                            Text("+\(counts.additions)").foregroundStyle(self.theme.added)
                            Text("−\(counts.deletions)").foregroundStyle(self.theme.removed)

                        } else {
                            Text("Line counts unavailable").foregroundStyle(self.theme.secondaryText)
                        }

                        if self.change.hasConflicts {
                            DiffyBadge(title: "Conflicts", color: self.theme.modified)
                        }

                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))

                }

            }
            .padding(18)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .help("Open working tree for \(self.change.project.displayName)")
        .accessibilityLabel(self.accessibilitySummary)

    }

}
