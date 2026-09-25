import SwiftUI

struct OverviewPullRequestRow: View {

    let request: AssignedPullRequestSummary
    let review: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

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

            }

            PullRequestActions(webURL: self.request.webURL, review: self.review)
                .padding(.leading, 37)

        }
        .padding(18)

    }

}
