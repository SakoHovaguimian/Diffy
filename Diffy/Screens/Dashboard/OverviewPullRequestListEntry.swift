enum OverviewPullRequestListEntry: Identifiable {

    case group(
        id: OverviewPullRequestGroupID,
        title: String,
        count: Int,
        isAuthor: Bool,
        isLastSection: Bool,
        hasSeparator: Bool
    )
    case request(
        summary: AssignedPullRequestSummary,
        showsRepository: Bool,
        showsAuthor: Bool,
        isGrouped: Bool,
        hasSeparator: Bool
    )

    var id: ID {

        switch self {

        case let .group(group, _, _, _, _, _): .group(group)
        case let .request(request, _, _, _, _): .request(request.id)

        }

    }

    enum ID: Hashable {
        case group(OverviewPullRequestGroupID)
        case request(String)
    }

}
