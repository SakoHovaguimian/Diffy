import SwiftUI

struct OverviewPullRequestList: View {

    let requests: [AssignedPullRequestSummary]
    let sortOrder: OverviewPullRequestSortOrder
    let hasFooter: Bool
    @Binding var collapsedGroups: Set<OverviewPullRequestGroupID>
    let review: (AssignedPullRequestSummary) -> Void
    @Environment(\.diffyTheme) private var theme

    private var repositories: [String] {

        Set(self.requests.map(\.repositoryFullName))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    }

    var body: some View {

        LazyVStack(spacing: 0) {

            if self.sortOrder == .repository || self.sortOrder == .author {
                ForEach(self.repositories, id: \.self) { repository in
                    repositoryRows(repository)
                }
            } else {
                requestRows(self.requests, showsRepository: true, showsAuthor: true, isGrouped: false)
            }

        }

    }

    private func repositoryRows(_ repository: String) -> some View {

        let requests = self.requests.filter { $0.repositoryFullName == repository }
        let group = OverviewPullRequestGroupID.repository(repository)

        return VStack(spacing: 0) {

            if repository != self.repositories.first {
                self.theme.border.frame(height: 1)
            }

            groupHeader(
                repository,
                count: requests.count,
                group: group,
                isAuthor: false,
                isLastSection: repository == self.repositories.last && !self.hasFooter
            )

            if !self.collapsedGroups.contains(group) {

                if self.sortOrder == .author {
                    ForEach(authors(in: requests), id: \.self) { author in
                        authorRows(author, in: requests, repository: repository)
                    }
                } else {
                    requestRows(requests, showsRepository: false, showsAuthor: true, isGrouped: true)
                }

            }

        }

    }

    private func authorRows(_ author: String, in requests: [AssignedPullRequestSummary], repository: String) -> some View {

        let authoredRequests = requests.filter { $0.author.login == author }
        let group = OverviewPullRequestGroupID.author(repository: repository, login: author)

        return VStack(spacing: 0) {

            groupHeader(
                author,
                count: authoredRequests.count,
                group: group,
                isAuthor: true,
                isLastSection: repository == self.repositories.last && author == authors(in: requests).last && !self.hasFooter
            )

            if !self.collapsedGroups.contains(group) {
                requestRows(authoredRequests, showsRepository: false, showsAuthor: false, isGrouped: true)
            }

        }

    }

    private func groupHeader(
        _ title: String,
        count: Int,
        group: OverviewPullRequestGroupID,
        isAuthor: Bool,
        isLastSection: Bool
    ) -> some View {

        let isCollapsed = self.collapsedGroups.contains(group)
        let groupName = isAuthor ? "author \(title)" : "repository \(title)"
        let action = isCollapsed ? "Expand" : "Collapse"

        return Button { toggle(group) } label: {

            HStack(spacing: 8) {

                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 12)
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Text(count.formatted())
                    .foregroundStyle(self.theme.secondaryText)

            }
            .font(.system(size: isAuthor ? 10 : 11, weight: isAuthor ? .medium : .semibold))
            .foregroundStyle(isAuthor ? self.theme.secondaryText : self.theme.text)
            .padding(.leading, isAuthor ? 37 : 18)
            .padding(.trailing, 18)
            .padding(.top, isAuthor ? 8 : 12)
            .padding(.bottom, isCollapsed && isLastSection ? 16 : isAuthor ? 2 : 4)
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .help("\(action) \(groupName)")
        .accessibilityLabel("\(action) \(groupName)")
        .accessibilityHint("Shows or hides \(count) pull request\(count == 1 ? "" : "s")")

    }

    private func toggle(_ group: OverviewPullRequestGroupID) {

        if self.collapsedGroups.contains(group) {
            self.collapsedGroups.remove(group)
        } else {
            self.collapsedGroups.insert(group)
        }

    }

    private func authors(in requests: [AssignedPullRequestSummary]) -> [String] {

        Set(requests.map(\.author.login))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    }

    private func requestRows(
        _ requests: [AssignedPullRequestSummary],
        showsRepository: Bool,
        showsAuthor: Bool,
        isGrouped: Bool
    ) -> some View {

        ForEach(requests) { request in

            OverviewPullRequestRow(
                request: request,
                showsRepository: showsRepository,
                showsAuthor: showsAuthor,
                isGrouped: isGrouped
            ) {
                self.review(request)
            }

            if request.id != requests.last?.id {
                self.theme.border.frame(height: 1).padding(.leading, 18)
            }

        }

    }

}
