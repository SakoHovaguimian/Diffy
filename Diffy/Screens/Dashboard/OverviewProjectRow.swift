import SwiftUI

struct OverviewProjectRow: View {

    let change: OverviewProjectChange
    let bucket: Bucket?
    let open: () -> Void
    var pull: (() -> Void)?
    var fetch: (() -> Void)?
    @Environment(\.diffyTheme) private var theme

    private var tint: Color {
        self.bucket.map { Color(hex: $0.accentHex) } ?? self.change.project.accentHex.map { Color(hex: $0) } ?? self.theme.accent
    }

    private var accessibilitySummary: String {

        let counts = self.change.lineCounts.map { ", plus \($0.additions) lines, minus \($0.deletions) lines" } ?? ", line counts unavailable"
        let conflicts = self.change.hasConflicts ? ", conflicts" : ""
        let remote: String

        if let upstream = self.change.upstream {

            remote = switch self.change.upstreamRemoteState {
            case .current: ", \(upstream.ahead) ahead and \(upstream.behind) behind \(upstream.name)"
            case .checking: ", checking \(upstream.name)"
            case .changed: ", \(upstream.name) changed on the remote; fetch for counts"
            case .unavailable: ", could not verify \(upstream.name)"
            }

        } else {
            remote = ""
        }

        return "\(self.change.project.displayName), \(self.change.changedFileCount) changed files\(counts)\(conflicts)\(remote)"

    }

    var body: some View {

        HStack(spacing: 0) {

            Button(action: self.open) {

                HStack(alignment: .top, spacing: 13) {

                    WorkspaceIdentityIcon(symbol: self.change.project.symbol, customIcon: self.change.project.customIcon, size: 18)
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

                            Text(self.change.changedFileCount == 0 ? "Working Tree Clean" : "\(self.change.changedFileCount) Changed Files")
                                .foregroundStyle(self.theme.secondaryText)

                            if self.change.changedFileCount > 0, let counts = self.change.lineCounts {

                                Text("+\(counts.additions)").foregroundStyle(self.theme.countColor(for: counts.additions, activeColor: self.theme.added))
                                Text("−\(counts.deletions)").foregroundStyle(self.theme.countColor(for: counts.deletions, activeColor: self.theme.removed))

                            } else if self.change.changedFileCount > 0 {
                                Text("Line Counts Unavailable").foregroundStyle(self.theme.secondaryText)
                            }

                            if self.change.hasConflicts {
                                DiffyBadge(title: "Conflicts", color: self.theme.modified)
                            }

                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))

                        if let upstream = self.change.upstream {

                            switch self.change.upstreamRemoteState {

                            case .current:
                                if upstream.ahead > 0 || upstream.behind > 0 {
                                    Text("\(upstream.ahead) ahead · \(upstream.behind) behind \(upstream.name) · checked \(self.change.remoteCheckedAt?.formatted(date: .omitted, time: .shortened) ?? "recently")")
                                        .font(.system(size: 10))
                                        .foregroundStyle(self.theme.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                            case .changed:
                                Text("\(upstream.name) changed on the remote. Fetch for exact counts.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(self.theme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)

                            case .unavailable, .checking:
                                Text("Couldn’t verify \(upstream.name). Fetch to update branch counts.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(self.theme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)

                            }

                        }

                    }

                }
                .padding(18)
                .contentShape(Rectangle())

            }
            .buttonStyle(.plain)
            .help("Open Working Tree For \(self.change.project.displayName)")
            .accessibilityLabel(self.accessibilitySummary)

            if let pull = self.pull, self.change.upstreamRemoteState == .current, (self.change.upstream?.behind ?? 0) > 0 {
                Button("Pull", action: pull)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.trailing, 18)
                    .help("Pull \(self.change.upstream?.name ?? "Tracked Upstream") & Review Changes")
            } else if let fetch = self.fetch, self.change.upstream != nil, self.change.upstreamRemoteState != .current {
                Button("Fetch", action: fetch)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.trailing, 18)
                    .help("Fetch \(self.change.upstream?.name ?? "Tracked Upstream") To Update Counts")
            }

        }

    }

}
