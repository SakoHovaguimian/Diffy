import SwiftUI

struct OverviewPullRequestList: View {

    let requests: [AssignedPullRequestSummary]
    let sortOrder: OverviewPullRequestSortOrder
    let hasFooter: Bool
    @Binding var collapsedGroups: Set<OverviewPullRequestGroupID>
    let loadDetails: (AssignedPullRequestSummary) async -> Void
    let review: (AssignedPullRequestSummary) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        let entries = OverviewPullRequestListBuilder(
            collapsedGroups: self.collapsedGroups,
            hasFooter: self.hasFooter
        ).entries(for: self.requests, sortOrder: self.sortOrder)

        return LazyVStack(spacing: 0) {
            ForEach(entries) { entry in
                entryView(entry)
            }
        }

    }

    @ViewBuilder
    private func entryView(_ entry: OverviewPullRequestListEntry) -> some View {

        switch entry {

        case let .group(group, title, count, isAuthor, isLastSection, hasSeparator):

            VStack(spacing: 0) {

                if hasSeparator {
                    self.theme.border.frame(height: 1)
                }
                groupHeader(title, count: count, group: group, isAuthor: isAuthor, isLastSection: isLastSection)

            }

        case let .request(request, showsRepository, showsAuthor, isGrouped, hasSeparator):

            VStack(spacing: 0) {

                OverviewPullRequestRow(
                    request: request,
                    showsRepository: showsRepository,
                    showsAuthor: showsAuthor,
                    isGrouped: isGrouped
                ) {
                    self.review(request)
                }
                .task(id: request.id) {
                    await self.loadDetails(request)
                }

                if hasSeparator {
                    self.theme.border.frame(height: 1).padding(.leading, 18)
                }

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

}
