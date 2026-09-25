import SwiftUI

struct RepositoryCommitRow: View {

    let commit: RepositoryCommit
    let showsConnector: Bool
    let action: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Button(action: self.action) {

            HStack(alignment: .top, spacing: 14) {

                VStack(spacing: 5) {

                    Circle().stroke(self.theme.accent, lineWidth: 2).frame(width: 9, height: 9)
                    if self.showsConnector { self.theme.border.frame(width: 1, height: 38) }

                }
                .padding(.top, 4)
                VStack(alignment: .leading, spacing: 8) {

                    Text(self.commit.title).font(.system(size: 13, weight: .medium)).lineLimit(2).multilineTextAlignment(.leading)
                    HStack(spacing: 8) {

                        Text(self.commit.shortID).font(.system(size: 10, design: .monospaced)).foregroundStyle(self.theme.accent)
                        Text(self.commit.authorName)
                        Text("·")
                        Text(self.commit.authoredAt, format: .dateTime.month(.abbreviated).day().hour().minute())

                    }
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)

                }
                Spacer(minLength: 0)
                if self.commit.isMergeCommit { Image(systemName: "arrow.triangle.merge").foregroundStyle(self.theme.secondaryText) }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .help("Inspect Commit \(self.commit.shortID)")
        .accessibilityLabel("\(self.commit.title), by \(self.commit.authorName), \(self.commit.shortID)")

    }

}
