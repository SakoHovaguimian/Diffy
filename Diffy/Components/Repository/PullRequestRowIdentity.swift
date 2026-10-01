import SwiftUI

struct PullRequestRowIdentity: View {

    let content: PullRequestRowContent
    let showsAuthor: Bool
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var statusColor: Color {
        self.content.lifecycle.color(in: self.theme, isDraft: self.content.isDraft)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: self.contentSize.scaled(10)) {

            title()
            metadata()

            if let summary = self.content.summary {

                branches(summary)

                PullRequestPeopleSummary(
                    assignees: summary.assignees,
                    requestedReviewers: summary.requestedReviewers
                )

                if !summary.requestedTeams.isEmpty {

                    Label(summary.requestedTeams.map(\.name).joined(separator: ", "), systemImage: "person.2")
                        .font(self.contentSize.font(size: 10))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(2)
                        .help("Team review requested: \(summary.requestedTeams.map(\.name).joined(separator: ", "))")

                }

            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private func title() -> some View {

        HStack(alignment: .top, spacing: self.contentSize.scaled(10)) {

            Text(self.content.title)
                .font(self.contentSize.font(size: 14, weight: .semibold))
                .foregroundStyle(self.theme.text)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .help(self.content.title)

            Text(self.content.statusTitle)
                .font(self.contentSize.font(size: 10, weight: .semibold))
                .foregroundStyle(self.statusColor)
                .padding(.horizontal, self.contentSize.scaled(9))
                .padding(.vertical, self.contentSize.scaled(3))
                .background(self.statusColor.opacity(0.09), in: Capsule())
                .overlay(Capsule().strokeBorder(self.statusColor.opacity(0.25), lineWidth: 1))
                .fixedSize()

        }

    }

    private func metadata() -> some View {

        ViewThatFits(in: .horizontal) {

            HStack(spacing: self.contentSize.scaled(10)) {

                author()
                updatedDate()

                if let repository = self.content.repositoryFullName {
                    repositoryChip(repository)
                }

            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: self.contentSize.scaled(7)) {

                ViewThatFits(in: .horizontal) {

                    HStack(spacing: self.contentSize.scaled(10)) {

                        author()
                        updatedDate()

                    }
                    .fixedSize(horizontal: true, vertical: false)

                    VStack(alignment: .leading, spacing: self.contentSize.scaled(7)) {

                        author()
                        updatedDate()

                    }

                }

                if let repository = self.content.repositoryFullName {
                    repositoryChip(repository)
                }

            }

        }
        .font(self.contentSize.font(size: 10))
        .foregroundStyle(self.theme.secondaryText)

    }

    private func author() -> some View {

        HStack(spacing: self.contentSize.scaled(6)) {

            if self.showsAuthor {
                GitHubAvatar(user: self.content.author, size: self.contentSize.scaled(18))
            }

            Text("#\(self.content.number.formatted(.number.grouping(.never)))")
                .monospacedDigit()
                .fixedSize()

            if self.showsAuthor {

                Text(self.content.author.login)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help("@\(self.content.author.login)")

            }

        }

    }

    private func updatedDate() -> some View {

        Label(self.content.updatedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            .fixedSize()
            .help("Updated \(self.content.updatedAt.formatted(date: .long, time: .shortened))")

    }

    private func repositoryChip(_ repository: String) -> some View {

        Label(repository, systemImage: "externaldrive")
            .font(self.contentSize.font(size: 10, weight: .medium))
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, self.contentSize.scaled(7))
            .padding(.vertical, self.contentSize.scaled(3))
            .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(5)))
            .overlay(RoundedRectangle(cornerRadius: self.contentSize.scaled(5)).strokeBorder(self.theme.border, lineWidth: 1))
            .help(repository)

    }

    private func branches(_ summary: PullRequestSummary) -> some View {

        HStack(spacing: self.contentSize.scaled(9)) {

            branchChip(summary.headRef)

            Image(systemName: "arrow.right")
                .foregroundStyle(self.theme.secondaryText)
                .accessibilityHidden(true)

            branchChip(summary.baseRef)

        }
        .font(self.contentSize.font(size: 10, weight: .medium, design: .monospaced))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Merge \(summary.headRef) into \(summary.baseRef)")

    }

    private func branchChip(_ branch: String) -> some View {

        Label(branch, systemImage: "arrow.triangle.branch")
            .foregroundStyle(self.theme.secondaryText)
            .lineLimit(1)
            .truncationMode(.middle)
            .padding(.horizontal, self.contentSize.scaled(8))
            .padding(.vertical, self.contentSize.scaled(6))
            .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(6)))
            .overlay(RoundedRectangle(cornerRadius: self.contentSize.scaled(6)).strokeBorder(self.theme.border, lineWidth: 1))
            .help(branch)

    }

}
