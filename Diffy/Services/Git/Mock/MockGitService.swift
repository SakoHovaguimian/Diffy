import Foundation

struct MockGitService: GitServiceProtocol {

    func executableStatus() async -> GitExecutableStatus {
        GitExecutableStatus(path: nil, version: "Preview", problem: "Mock mode never runs Git.", isCustomPath: false)
    }

    func configureExecutable(customPath: String?) async -> GitExecutableStatus {
        await executableStatus()
    }

    func locateRepository(_ repository: GitRepositoryReference) async throws -> GitRepositoryLocation {
        GitRepositoryLocation(rootPath: repository.checkout.lastKnownPath, gitDirectoryPath: "/preview/.git", commonDirectoryPath: "/preview/.git")
    }

    func snapshot(of repository: GitRepositoryReference, scope: GitSnapshotScope, previous: GitRepositorySnapshot?) async throws -> GitRepositorySnapshot {

        let files = MockWorkspaceFixtures.files(for: repository.projectID)
        let branch = "feature/refine-the-details"
        let changes = files.filter { $0.status != .identical }.map { file in

            GitFileChange(path: file.path, originalPath: file.originalPath, indexStatus: file.isStaged ? .modified : .unmodified, worktreeStatus: file.isStaged ? .unmodified : .modified, conflict: file.status == .conflicted ? .bothModified : nil)

        }

        return GitRepositorySnapshot(
            location: try await locateRepository(repository),
            head: GitHeadState(branchName: branch, commitID: "a7e2c91"),
            upstream: GitUpstreamStatus(name: "origin/\(branch)", remoteName: "origin", ahead: 2, behind: 1),
            operation: .none, changes: changes,
            remotes: [GitRemote(name: "origin", fetchURL: "https://github.com/diffy/\(repository.projectID).git", pushURL: "https://github.com/diffy/\(repository.projectID).git")],
            branches: [branch, "main", "develop"].map { RepositoryBranch(name: $0, isRemote: false, commitID: "a7e2c91", isCurrent: $0 == branch) },
            tags: [RepositoryTag(name: "v1.4.0", commitID: "b4f1d08")],
            recentCommits: MockWorkspaceFixtures.commits, capturedAt: Date()
        )

    }

    func comparisonFiles(in repository: GitRepositoryReference, selection: ComparisonSelection) async throws -> [DiffFile] {
        MockWorkspaceFixtures.files(for: repository.projectID)
    }

    func fileComparison(in repository: GitRepositoryReference, selection: ComparisonSelection, file: DiffFile) async throws -> DiffFile {
        file
    }

    func imageSources(in repository: GitRepositoryReference, selection: ComparisonSelection, file: DiffFile) async throws -> ImageComparisonSources {
        ImageComparisonSources(original: nil, updated: nil)
    }

    func commits(in repository: GitRepositoryReference, revision: String?, limit: Int) async throws -> [RepositoryCommit] {
        Array(MockWorkspaceFixtures.commits.prefix(limit))
    }

    func fileHistory(in repository: GitRepositoryReference, path: String, limit: Int) async throws -> [RepositoryCommit] {
        Array(MockWorkspaceFixtures.commits.prefix(limit))
    }

    func conflictDocument(in repository: GitRepositoryReference, path: String) async throws -> GitConflictDocument {
        throw GitError.unsupported("Use the sample merge comparison in Mock mode.")
    }

    func suggestedPullStrategy(in repository: GitRepositoryReference) async -> GitPullStrategy {
        .fastForwardOnly
    }

    func folderComparisonFiles(left: URL, right: URL) async throws -> [DiffFile] {
        MockWorkspaceFixtures.files(for: "rune")
    }

    func folderFileComparison(left: URL, right: URL, file: DiffFile) async throws -> DiffFile {
        file
    }

    func patch(in repository: GitRepositoryReference, selection: ComparisonSelection) async throws -> String {

        let files = MockWorkspaceFixtures.files(for: repository.projectID).filter { selection.paths.isEmpty || selection.paths.contains($0.path) }
        return files.map { file in

            let lines = file.lines.map { line in

                switch line.status {

                case .added: "+" + (line.right ?? "")
                case .removed: "-" + (line.left ?? "")
                default: " " + (line.right ?? line.left ?? "")

                }

            }.joined(separator: "\n")
            return "diff --git a/\(file.path) b/\(file.path)\n@@ -1,20 +1,20 @@\n" + lines

        }.joined(separator: "\n")

    }

    func trackedPaths(in repository: GitRepositoryReference) async throws -> [String] {
        MockWorkspaceFixtures.files(for: repository.projectID).map(\.path)
    }

    func folderPatch(left: URL, right: URL) async throws -> String {
        "Choose Diffy Live to compare folders on this Mac."
    }

    func perform(_ request: GitOperationRequest, in repository: GitRepositoryReference, progress: @escaping @Sendable (GitOperationProgress) -> Void) async throws -> GitOperationResult {
        throw GitError.unsupported("Mock mode keeps sample repositories immutable. Open Diffy Live to run Git actions.")
    }

    func applyMergeResult(_ content: String, path: String, stagesResult: Bool, in repository: GitRepositoryReference) async throws {
        throw GitError.unsupported("Mock mode does not write repository files.")
    }

    func fetchPullRequestSources(_ pullRequest: PullRequestSummary, remoteName: String, in repository: GitRepositoryReference, progress: @escaping @Sendable (GitOperationProgress) -> Void) async throws -> ComparisonSelection {
        ComparisonSelection(left: .revision(pullRequest.baseSHA), right: .revision(pullRequest.headSHA))
    }

    func clone(_ request: GitCloneRequest, progress: @escaping @Sendable (GitOperationProgress) -> Void) async throws -> URL {
        throw GitError.unsupported("Mock mode never clones repositories.")
    }

}
