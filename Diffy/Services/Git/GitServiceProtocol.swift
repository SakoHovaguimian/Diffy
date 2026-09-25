import Foundation

/// Local Git access. Live implementations invoke the Git executable with argument arrays;
/// mock implementations return immutable fixtures and never run Git.
///
/// Read methods never change the repository. Only `perform`, `applyMergeResult`,
/// `fetchPullRequestSources`, and `clone` write, and only after an explicit user action.
protocol GitServiceProtocol: Sendable {

    // MARK: - Executable

    func executableStatus() async -> GitExecutableStatus
    func configureExecutable(customPath: String?) async -> GitExecutableStatus

    // MARK: - Repository Reads

    func locateRepository(_ repository: GitRepositoryReference) async throws -> GitRepositoryLocation

    func snapshot(
        of repository: GitRepositoryReference,
        scope: GitSnapshotScope,
        previous: GitRepositorySnapshot?
    ) async throws -> GitRepositorySnapshot

    func comparisonFiles(
        in repository: GitRepositoryReference,
        selection: ComparisonSelection
    ) async throws -> [DiffFile]

    func fileComparison(
        in repository: GitRepositoryReference,
        selection: ComparisonSelection,
        file: DiffFile
    ) async throws -> DiffFile

    func imageSources(
        in repository: GitRepositoryReference,
        selection: ComparisonSelection,
        file: DiffFile
    ) async throws -> ImageComparisonSources

    func commits(
        in repository: GitRepositoryReference,
        revision: String?,
        limit: Int
    ) async throws -> [RepositoryCommit]

    func fileHistory(
        in repository: GitRepositoryReference,
        path: String,
        limit: Int
    ) async throws -> [RepositoryCommit]

    func conflictDocument(
        in repository: GitRepositoryReference,
        path: String
    ) async throws -> GitConflictDocument

    func suggestedPullStrategy(in repository: GitRepositoryReference) async -> GitPullStrategy

    // MARK: - Folder Comparison

    func folderComparisonFiles(
        left: URL,
        right: URL
    ) async throws -> [DiffFile]

    func folderFileComparison(
        left: URL,
        right: URL,
        file: DiffFile
    ) async throws -> DiffFile

    // MARK: - Explicit Actions

    func perform(
        _ request: GitOperationRequest,
        in repository: GitRepositoryReference,
        progress: @escaping @Sendable (GitOperationProgress) -> Void
    ) async throws -> GitOperationResult

    /// Atomically writes a resolved file after the user chooses Apply. Stages it only
    /// when `stagesResult` is true.
    func applyMergeResult(
        _ content: String,
        path: String,
        stagesResult: Bool,
        in repository: GitRepositoryReference
    ) async throws

    /// Makes a pull request's base and head commits available locally without creating
    /// branches, then returns the comparison to show.
    func fetchPullRequestSources(
        _ pullRequest: PullRequestSummary,
        remoteName: String,
        in repository: GitRepositoryReference,
        progress: @escaping @Sendable (GitOperationProgress) -> Void
    ) async throws -> ComparisonSelection

    func clone(
        _ request: GitCloneRequest,
        progress: @escaping @Sendable (GitOperationProgress) -> Void
    ) async throws -> URL

}
