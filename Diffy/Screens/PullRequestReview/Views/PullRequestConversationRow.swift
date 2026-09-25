import SwiftUI

struct PullRequestConversationRow: View {

    let entry: PullRequestConversationEntry
    let reply: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 10) {

                Text(self.entry.author).fontWeight(.semibold)
                Text(self.entry.title).foregroundStyle(self.theme.secondaryText)
                Spacer()
                if let date = self.entry.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened)).foregroundStyle(self.theme.secondaryText)
                }
                if let url = self.entry.webURL {
                    Link(destination: url) { Image(systemName: "arrow.up.right") }.help("Open Discussion On GitHub")
                }

            }
            .font(.system(size: 11))
            if let path = self.entry.path {

                Text("\(path)\(self.entry.line.map { " · \(self.entry.side == "LEFT" ? "Old" : "New") Line \($0)" } ?? " · Outdated")\(self.entry.replyToID == nil ? "" : " · Reply")")
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(self.theme.secondaryText)

            }
            if !self.entry.body.isEmpty {
                Text(self.entry.body).font(.system(size: 12)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if self.entry.kind == .inline {
                Button("Reply", action: self.reply).controlSize(.small)
            }

        }
        .padding(16)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border))

    }

}
