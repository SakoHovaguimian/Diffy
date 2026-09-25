import Foundation

enum AIContextBuilder {

    static func makeContext(
        details: PullRequestReviewDetails,
        repositoryIdentity: String,
        commits: [AICommitContext] = [],
        selectedPaths: [String] = [],
        annotations: [CodeAnnotation] = []
    ) -> AIReviewContext {

        let selected = Set(selectedPaths)
        let commitContexts = commits.isEmpty
            ? details.commits.map { AICommitContext(sha: $0.id, title: $0.title, author: $0.authorName) }
            : commits
        let eligibleFiles = selected.isEmpty
            ? details.files
            : details.files.filter { selected.contains($0.filename) }
        let orderedFiles = eligibleFiles.sorted {
            $0.additions + $0.deletions > $1.additions + $1.deletions
        }

        var remainingPatchCharacters = 70_000
        let files = orderedFiles.prefix(28).map { file -> AIFileSnapshot in

            let patch = remainingPatchCharacters > 0
                ? file.patch.map { String($0.prefix(min(5_000, remainingPatchCharacters))) }
                : nil
            remainingPatchCharacters -= patch?.count ?? 0

            return AIFileSnapshot(
                filename: file.filename,
                previousFilename: file.previousFilename,
                status: file.status,
                additions: file.additions,
                deletions: file.deletions,
                patch: patch
            )

        }

        let inventory = eligibleFiles.prefix(800).map(\.filename)
        var omissions: [String] = []

        if !selected.isEmpty {
            omissions.append("Analysis was restricted to \(eligibleFiles.count) selected files; \(details.files.count - eligibleFiles.count) other changed files were excluded.")
        }

        if eligibleFiles.count > files.count {
            omissions.append("Only \(files.count) of \(eligibleFiles.count) eligible file patches were included.")
        }

        if selected.count > eligibleFiles.count {
            omissions.append("Some selected paths were not in the loaded PR file list.")
        }

        if eligibleFiles.count > inventory.count {
            omissions.append("The file inventory omitted \(eligibleFiles.count - inventory.count) paths.")
        }

        if files.contains(where: { $0.patch == nil }) {
            omissions.append("Some GitHub patches were unavailable or omitted for binary or oversized files.")
        }

        if files.contains(where: { snapshot in
            details.files.first(where: { $0.filename == snapshot.filename })?.patch?.count ?? 0 > snapshot.patch?.count ?? 0
        }) {
            omissions.append("Long patches were truncated. Do not infer behavior beyond the provided hunks.")
        }

        let noteContexts = annotations.prefix(20).map {
            AIAnnotationContext(annotation: $0).boundedForPrompt()
        }

        if annotations.count > noteContexts.count {
            omissions.append("Only \(noteContexts.count) of \(annotations.count) review notes were included.")
        }

        if details.body.count > 12_000 {
            omissions.append("The PR description was truncated after 12,000 characters.")
        }

        if commitContexts.count > 80 {
            omissions.append("Only the first 80 of \(commitContexts.count) commit summaries were included.")
        }

        if !details.hasAllCommits {
            omissions.append("GitHub did not provide the complete commit list for this PR.")
        }

        if !details.hasAllFiles {
            omissions.append("GitHub did not provide the complete changed-file list for this PR.")
        }

        return AIReviewContext(
            repositoryIdentity: repositoryIdentity,
            pullRequestNumber: details.summary.number,
            title: details.summary.title,
            author: details.summary.author.login,
            baseSHA: details.summary.baseSHA,
            headSHA: details.summary.headSHA,
            description: String(details.body.prefix(12_000)),
            commits: Array(commitContexts.prefix(80)),
            selectedPaths: selected.sorted(),
            fileInventory: inventory,
            files: files,
            annotations: noteContexts,
            selectedAnnotationCount: annotations.count,
            omissions: omissions
        )

    }
}
