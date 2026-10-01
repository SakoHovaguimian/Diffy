import SwiftUI

struct PullRequestPeopleSummary: View {

    let assignees: [GitHubUserSummary]
    let requestedReviewers: [GitHubUserSummary]
    var avatarSize: CGFloat = 24
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    private let maximumVisibleUsers = 5

    var body: some View {

        if !self.assignees.isEmpty || !self.requestedReviewers.isEmpty {

            ViewThatFits(in: .horizontal) {

                HStack(spacing: self.contentSize.scaled(14)) {
                    groups()
                }

                VStack(alignment: .leading, spacing: self.contentSize.scaled(7)) {
                    groups()
                }

            }

        }

    }

    @ViewBuilder
    private func groups() -> some View {

        if !self.assignees.isEmpty {
            peopleGroup("\(self.assignees.count) assignee\(self.assignees.count == 1 ? "" : "s")", users: self.assignees)
        }

        if !self.requestedReviewers.isEmpty {
            peopleGroup("\(self.requestedReviewers.count) reviewer\(self.requestedReviewers.count == 1 ? "" : "s") requested", users: self.requestedReviewers)
        }

    }

    private func peopleGroup(_ title: String, users: [GitHubUserSummary]) -> some View {

        HStack(spacing: self.contentSize.scaled(7)) {

            Text(title)
                .font(self.contentSize.font(size: 10, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)
                .fixedSize()

            HStack(spacing: self.contentSize.scaled(-4)) {

                ForEach(users.prefix(self.maximumVisibleUsers)) { user in
                    GitHubAvatar(user: user, size: self.contentSize.scaled(self.avatarSize))
                }

                if users.count > self.maximumVisibleUsers {

                    Text("+\(users.count - self.maximumVisibleUsers)")
                        .font(self.contentSize.font(size: max(7, self.avatarSize * 0.36), weight: .semibold))
                        .foregroundStyle(self.theme.secondaryText)
                        .frame(width: self.contentSize.scaled(self.avatarSize), height: self.contentSize.scaled(self.avatarSize))
                        .background(self.theme.elevated, in: Circle())
                        .overlay(Circle().strokeBorder(self.theme.border, lineWidth: 0.75))

                }

            }

        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(users.map { "@\($0.login)" }.joined(separator: ", "))")

    }

}
