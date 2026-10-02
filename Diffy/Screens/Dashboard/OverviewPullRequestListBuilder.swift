import Foundation

/// Flattens group headings and requests into one lazy list with stable row identities.
struct OverviewPullRequestListBuilder {

    let collapsedGroups: Set<OverviewPullRequestGroupID>
    let hasFooter: Bool

    init(
        collapsedGroups: Set<OverviewPullRequestGroupID>,
        hasFooter: Bool
    ) {

        self.collapsedGroups = collapsedGroups
        self.hasFooter = hasFooter

    }

    func entries(for requests: [AssignedPullRequestSummary], sortOrder: OverviewPullRequestSortOrder) -> [OverviewPullRequestListEntry] {

        if sortOrder == .repository || sortOrder == .author {
            return repositoryEntries(for: requests, groupsAuthors: sortOrder == .author)
        }
        return requestEntries(for: requests, showsRepository: true, showsAuthor: true, isGrouped: false)

    }

    private func repositoryEntries(for requests: [AssignedPullRequestSummary], groupsAuthors: Bool) -> [OverviewPullRequestListEntry] {

        let groups = Dictionary(grouping: requests, by: \.repositoryFullName)
        let repositories = sortedNames(groups.keys)
        var entries: [OverviewPullRequestListEntry] = []

        for repository in repositories {

            let requests = groups[repository] ?? []
            let group = OverviewPullRequestGroupID.repository(repository)
            let isLast = repository == repositories.last
            entries.append(.group(
                id: group,
                title: repository,
                count: requests.count,
                isAuthor: false,
                isLastSection: isLast && !self.hasFooter,
                hasSeparator: repository != repositories.first
            ))
            guard !self.collapsedGroups.contains(group) else { continue }

            if groupsAuthors {
                entries.append(contentsOf: authorEntries(for: requests, repository: repository, isLastRepository: isLast))
            } else {
                entries.append(contentsOf: requestEntries(for: requests, showsRepository: false, showsAuthor: true, isGrouped: true))
            }

        }

        return entries

    }

    private func authorEntries(for requests: [AssignedPullRequestSummary], repository: String, isLastRepository: Bool) -> [OverviewPullRequestListEntry] {

        let groups = Dictionary(grouping: requests, by: \.author.login)
        let authors = sortedNames(groups.keys)
        var entries: [OverviewPullRequestListEntry] = []

        for author in authors {

            let requests = groups[author] ?? []
            let group = OverviewPullRequestGroupID.author(repository: repository, login: author)
            entries.append(.group(
                id: group,
                title: author,
                count: requests.count,
                isAuthor: true,
                isLastSection: isLastRepository && author == authors.last && !self.hasFooter,
                hasSeparator: false
            ))
            guard !self.collapsedGroups.contains(group) else { continue }
            entries.append(contentsOf: requestEntries(for: requests, showsRepository: false, showsAuthor: false, isGrouped: true))

        }

        return entries

    }

    private func requestEntries(
        for requests: [AssignedPullRequestSummary],
        showsRepository: Bool,
        showsAuthor: Bool,
        isGrouped: Bool
    ) -> [OverviewPullRequestListEntry] {

        requests.enumerated().map { index, request in

            .request(
                summary: request,
                showsRepository: showsRepository,
                showsAuthor: showsAuthor,
                isGrouped: isGrouped,
                hasSeparator: index < requests.count - 1
            )

        }

    }

    private func sortedNames(_ names: Dictionary<String, [AssignedPullRequestSummary]>.Keys) -> [String] {
        names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

}
