import Foundation

extension LiveGitService {

    func branchReview(in repository: GitRepositoryReference, branch: RepositoryBranch, base: String) async throws -> GitBranchReview {

        let selectedURL = try self.access.beginAccess(projectID: repository.projectID, checkout: repository.checkout)
        defer { self.access.endAccess(projectID: repository.projectID) }
        let root = try await repositoryRoot(at: selectedURL)
        let baseCommit = try await resolvedRevision(base, at: root)
        let branchCommit = try await resolvedRevision(branch.name, at: root)

        guard baseCommit != branchCommit else {
            return GitBranchReview(selection: nil, detail: "\(branch.name) and \(base) point to the same commit.", emptyMessage: "These references have no distinct changes.")
        }

        let common = try await self.runner.run(["merge-base", baseCommit, branchCommit], directory: root, acceptsFailure: true)

        guard common.status == 0 else {
            return GitBranchReview(selection: nil, detail: "\(branch.name) and \(base) have unrelated histories.", emptyMessage: "There is no merge base for a branch diff.")
        }

        if common.trimmed != branchCommit {
            return GitBranchReview(
                selection: ComparisonSelection(left: .revision(baseCommit), right: .revision(branchCommit), usesMergeBase: true),
                detail: "\(branch.name) relative to merge base with \(base)",
                emptyMessage: "The branch has no file changes since its merge base with \(base)."
            )
        }

        if let mergeCommit = try await mergedCommit(for: branchCommit, into: baseCommit, at: root) {
            return GitBranchReview(
                selection: ComparisonSelection(left: .parent(of: mergeCommit), right: .revision(mergeCommit)),
                detail: "Changes merged from \(branch.name) into \(base) at \(mergeCommit.prefix(7))",
                emptyMessage: "The merge commit did not change any files."
            )
        }

        return GitBranchReview(
            selection: nil,
            detail: "\(branch.name) is already contained in \(base).",
            emptyMessage: "No distinct branch diff remains. A matching merge commit could not be identified; this can happen after a fast-forward, squash, or rewritten history."
        )

    }

    private func mergedCommit(for branchCommit: String, into baseCommit: String, at root: URL) async throws -> String? {

        let merges = try await self.runner.run(["log", "--first-parent", "--merges", "--format=%H", "-100", baseCommit], directory: root)

        for hash in merges.text.split(separator: "\n").map(String.init).reversed() {

            let parents = try await self.runner.run(["rev-list", "--parents", "-n", "1", hash], directory: root)
                .trimmed.split(whereSeparator: \.isWhitespace).map(String.init)

            for parent in parents.dropFirst(2) {
                let ancestor = try await self.runner.run(["merge-base", "--is-ancestor", branchCommit, parent], directory: root, acceptsFailure: true)
                if ancestor.status == 0 { return hash }
            }

        }

        return nil

    }
}
