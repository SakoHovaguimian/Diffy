import SwiftUI

struct PullRequestConversationRow: View {

    let entry: PullRequestConversationEntry
    var location: PullRequestConversationEntry?
    var canReply = true
    var openFile: (() -> Void)?
    let reply: () -> Void
    @Environment(\.diffyTheme) private var theme

    private var statusColor: Color {
        self.entry.color(in: self.theme)
    }

    private var codeLocation: PullRequestConversationEntry {
        self.location ?? self.entry
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            header()
            if let path = self.codeLocation.path {
                fileContext(path)
            }
            if !self.entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DiffyMarkdownView(markdown: self.entry.body, opensWebLinks: true)
                    .padding(18)
            }
            if self.entry.kind == .inline || self.entry.webURL != nil {
                actions()
            }

        }
        .background(self.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border, lineWidth: 1))

    }

    // MARK: - Author & Review State

    private func header() -> some View {

        HStack(spacing: 10) {

            if let user = self.entry.user {
                GitHubAvatar(user: user, size: 28)
            } else {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 23))
                    .foregroundStyle(self.theme.secondaryText)
                    .frame(width: 28, height: 28)
                    .accessibilityLabel("Deleted Account")
            }
            Text(self.entry.author)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(self.theme.text)
            Label(self.entry.title, systemImage: self.entry.symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(self.statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(self.statusColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
            Spacer(minLength: 8)
            if let date = self.entry.date {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(self.statusColor.opacity(0.05))
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    // MARK: - Code Location

    @ViewBuilder
    private func fileContext(_ path: String) -> some View {

        if let openFile = self.openFile {
            Button(action: openFile) { locationLabel(path, isInteractive: true) }
                .buttonStyle(.plain)
                .help("Open \(path) · \(self.codeLocation.locationTitle)")
                .accessibilityLabel("Open \(path), \(self.codeLocation.locationTitle)")
        } else {
            locationLabel(path, isInteractive: false)
        }

    }

    private func locationLabel(_ path: String, isInteractive: Bool) -> some View {

        HStack(spacing: 10) {

            DiffyPathIcon(path: path)
            Text(path)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .lineLimit(2)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            Text(self.codeLocation.locationTitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)
            if isInteractive {
                Image(systemName: "arrow.right").font(.system(size: 11, weight: .medium))
            }

        }
        .foregroundStyle(isInteractive ? self.theme.accent : self.theme.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(self.theme.background)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }
        .contentShape(Rectangle())

    }

    private func actions() -> some View {

        HStack(spacing: 12) {

            if self.entry.kind == .inline, let openFile = self.openFile {
                Button(action: openFile) { Label("View code", systemImage: "chevron.left.forwardslash.chevron.right") }
                    .buttonStyle(.plain)
                    .foregroundStyle(self.theme.accent)
            }
            if self.entry.kind == .inline {
                Button(action: self.reply) { Label("Reply", systemImage: "arrowshape.turn.up.left") }
                    .buttonStyle(.plain)
                    .foregroundStyle(self.theme.accent)
                    .disabled(!self.canReply)
            }
            Spacer()
            if let url = self.entry.webURL {
                Link(destination: url) { Label("View on GitHub", systemImage: "arrow.up.right") }
                    .foregroundStyle(self.theme.secondaryText)
            }

        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)

    }

}
