import Foundation

/// A disposable cache for immediate launch. Entries are replaced only after a successful
/// refresh. A corrupt entry is discarded on its own. Secrets are never cached.
protocol RepositoryCacheProtocol: Sendable {

    func loadSnapshot(projectID: String) async -> CachedEntry<GitRepositorySnapshot>?
    func saveSnapshot(_ snapshot: GitRepositorySnapshot, projectID: String) async

    func loadComparisonListing(projectID: String, selectionKey: String) async -> CachedEntry<[DiffFile]>?
    func saveComparisonListing(_ files: [DiffFile], projectID: String, selectionKey: String) async

    func loadPullRequests(projectID: String, accountID: String) async -> CachedEntry<CachedPullRequests>?
    func savePullRequests(_ pullRequests: CachedPullRequests, projectID: String, accountID: String) async

    func loadRepositorySummary(projectID: String, accountID: String) async -> CachedEntry<GitHubRepositorySummary>?
    func saveRepositorySummary(_ summary: GitHubRepositorySummary, projectID: String, accountID: String) async

    func removeEntries(projectID: String) async

    /// Removes every cache entry. Projects, accounts, annotations, preferences, merge
    /// drafts, and repository files are untouched.
    func clearAll() async throws

    func locationDescription() -> String?

}
