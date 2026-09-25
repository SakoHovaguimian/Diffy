import Foundation

enum OverviewPullRequestSortOrder: String, CaseIterable, Identifiable {
    case recentlyUpdated = "Recently Updated"
    case leastRecentlyUpdated = "Least Recently Updated"
    case repository = "Repository"
    case author = "Author"

    var id: Self { self }

    func sorted(_ requests: [AssignedPullRequestSummary]) -> [AssignedPullRequestSummary] {

        requests.sorted { left, right in

            switch self {

            case .recentlyUpdated:
                return compareDates(left, right, newestFirst: true)

            case .leastRecentlyUpdated:
                return compareDates(left, right, newestFirst: false)

            case .repository:
                let comparison = left.repositoryFullName.localizedStandardCompare(right.repositoryFullName)
                return comparison == .orderedSame ? compareDates(left, right, newestFirst: true) : comparison == .orderedAscending

            case .author:
                let repositoryComparison = left.repositoryFullName.localizedStandardCompare(right.repositoryFullName)
                if repositoryComparison != .orderedSame { return repositoryComparison == .orderedAscending }

                let authorComparison = left.author.login.localizedStandardCompare(right.author.login)
                return authorComparison == .orderedSame ? compareDates(left, right, newestFirst: true) : authorComparison == .orderedAscending

            }

        }

    }

    private func compareDates(_ left: AssignedPullRequestSummary, _ right: AssignedPullRequestSummary, newestFirst: Bool) -> Bool {

        if left.updatedAt != right.updatedAt {
            return newestFirst ? left.updatedAt > right.updatedAt : left.updatedAt < right.updatedAt
        }

        return left.id < right.id

    }
}
