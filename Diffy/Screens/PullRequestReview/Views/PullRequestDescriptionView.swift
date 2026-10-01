import SwiftUI

struct PullRequestDescriptionView: View {

    let details: PullRequestReviewDetails
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 10) {

                Image(systemName: "doc.text")
                    .foregroundStyle(self.theme.accent)
                Text("Description")
                    .font(.system(size: 14, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                GitHubAvatar(user: self.details.summary.author, size: 22)
                Text(self.details.summary.author.login)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(self.theme.elevated)
            .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

            if self.details.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No description provided.")
                    .font(.system(size: 13))
                    .foregroundStyle(self.theme.secondaryText)
                    .padding(20)
            } else {
                DiffyMarkdownView(markdown: self.details.body, opensWebLinks: true)
                    .padding(20)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border, lineWidth: 1))

    }

}
