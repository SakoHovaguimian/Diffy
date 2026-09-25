import SwiftUI

struct OverviewPullRequestRow: View {

    let request: AssignedPullRequestSummary
    let showsRepository: Bool
    let showsAuthor: Bool
    let isGrouped: Bool
    let review: () -> Void
    @Environment(\.diffyTheme) private var theme

    private var metadata: String {

        var details: [String] = []
        if self.showsRepository { details.append(self.request.repositoryFullName) }
        details.append("#\(self.request.number)")
        if self.showsAuthor { details.append(self.request.author.login) }

        return details.joined(separator: " · ")

    }

    var body: some View {

        VStack(alignment: .leading, spacing: self.isGrouped ? 8 : 14) {

            HStack(alignment: .top, spacing: 12) {

                Image(systemName: "arrow.triangle.pull")
                    .font(.system(size: 16))
                    .foregroundStyle(self.theme.added)
                    .frame(width: 25)

                VStack(alignment: .leading, spacing: self.isGrouped ? 5 : 7) {

                    Text(self.request.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(self.theme.text)
                        .lineLimit(2)

                    Text(self.metadata)
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
        .padding(.horizontal, 18)
        .padding(.vertical, self.isGrouped ? 10 : 18)

    }

}
