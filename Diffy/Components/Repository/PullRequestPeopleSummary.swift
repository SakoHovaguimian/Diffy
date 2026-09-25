import SwiftUI

struct PullRequestPeopleSummary: View {

    let assignees: [GitHubUserSummary]
    let requestedReviewers: [GitHubUserSummary]
    var avatarSize: CGFloat = 20
    @Environment(\.diffyTheme) private var theme
    private let maximumVisibleUsers = 5

    var body: some View {

        if !self.assignees.isEmpty || !self.requestedReviewers.isEmpty {

            ViewThatFits(in: .horizontal) {

                HStack(spacing: 14) {
                    groups()
                }

                VStack(alignment: .leading, spacing: 7) {
                    groups()
                }

            }

        }

    }

    @ViewBuilder
    private func groups() -> some View {

        if !self.assignees.isEmpty {
            peopleGroup("Assigned", users: self.assignees)
        }

        if !self.requestedReviewers.isEmpty {
            peopleGroup("Review Requested", users: self.requestedReviewers)
        }

    }

    private func peopleGroup(_ title: String, users: [GitHubUserSummary]) -> some View {

        HStack(spacing: 7) {

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)
                .fixedSize()

            HStack(spacing: -4) {

                ForEach(users.prefix(self.maximumVisibleUsers)) { user in
                    GitHubAvatar(user: user, size: self.avatarSize)
                }

                if users.count > self.maximumVisibleUsers {

                    Text("+\(users.count - self.maximumVisibleUsers)")
                        .font(.system(size: max(7, self.avatarSize * 0.36), weight: .semibold))
                        .foregroundStyle(self.theme.secondaryText)
                        .frame(width: self.avatarSize, height: self.avatarSize)
                        .background(self.theme.elevated, in: Circle())
                        .overlay(Circle().strokeBorder(self.theme.border, lineWidth: 0.75))

                }

            }

        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(users.map { "@\($0.login)" }.joined(separator: ", "))")

    }

}
