import SwiftUI

struct OverviewPullRequestRow: View {

    let request: AssignedPullRequestSummary
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Link(destination: self.request.webURL) {

            HStack(alignment: .top, spacing: 12) {

                Image(systemName: "arrow.triangle.pull")
                    .font(.system(size: 16))
                    .foregroundStyle(self.theme.added)
                    .frame(width: 25)

                VStack(alignment: .leading, spacing: 7) {

                    Text(self.request.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(self.theme.text)
                        .lineLimit(2)

                    Text("\(self.request.repositoryFullName) · #\(self.request.number) · \(self.request.author.login)")
                        .font(.system(size: 10))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)

                    Text("Updated \(self.request.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 10))
                        .foregroundStyle(self.theme.secondaryText)

                }

                Spacer(minLength: 4)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)

            }
            .padding(18)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .help("Open pull request #\(self.request.number) on GitHub")

    }

}
