enum OverviewPullRequestGroupID: Hashable {
    case repository(String)
    case author(repository: String, login: String)
}
