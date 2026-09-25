import Foundation

enum AIContextBuilder {

    static func makeCompleteRiskContext(
        details: PullRequestReviewDetails,
        repositoryIdentity: String,
        files: [AIFileSnapshot]
    ) -> AIReviewContext {

        var omissions: [String] = []
        if files.contains(where: { $0.patch?.contains("Binary files ") == true || $0.patch?.contains("GIT binary patch") == true }) {
            omissions.append("Binary changes were included as Git diff markers; their binary contents cannot be inspected as text.")
        }
        if !details.hasAllCommits {
            omissions.append("GitHub did not provide the complete commit list for this PR.")
        }

        return AIReviewContext(
            repositoryIdentity: repositoryIdentity,
            pullRequestNumber: details.summary.number,
            title: details.summary.title,
            author: details.summary.author.login,
            baseSHA: details.summary.baseSHA,
            headSHA: details.summary.headSHA,
            description: details.body,
            commits: details.commits.map {
                AICommitContext(sha: $0.id, title: $0.title, author: $0.authorName)
            },
            selectedPaths: [],
            fileInventory: files.map(\.filename),
            files: files,
            annotations: [],
            selectedAnnotationCount: 0,
            omissions: omissions,
            pullRequestConversation: details.conversation.map(AICommentContext.init)
        )

    }

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

        let suppliedPaths = files.map(\.filename)
        let suppliedPathSet = Set(suppliedPaths)
        let remainingPaths = eligibleFiles.lazy.map(\.filename)
            .filter { !suppliedPathSet.contains($0) }
            .prefix(max(0, 800 - suppliedPaths.count))
        let inventory = suppliedPaths + Array(remainingPaths)
        var omissions: [String] = []

        if !selected.isEmpty {
            omissions.append("Analysis was restricted to \(eligibleFiles.count) selected files; \(details.files.count - eligibleFiles.count) other changed files were excluded.")
        }

        if eligibleFiles.count > files.count {
            omissions.append("Only \(files.count) of \(eligibleFiles.count) eligible changed files were selected for this request.")
        }

        if selected.count > eligibleFiles.count {
            omissions.append("Some selected paths were not in the loaded PR file list.")
        }

        if eligibleFiles.count > inventory.count {
            omissions.append("The file inventory omitted \(eligibleFiles.count - inventory.count) paths.")
        }

        let selectedFiles = Array(orderedFiles.prefix(files.count))
        let unavailablePatchCount = selectedFiles.filter { $0.patch == nil }.count
        if unavailablePatchCount > 0 {
            omissions.append("GitHub did not provide text patches for \(unavailablePatchCount) selected files, which may be binary or oversized.")
        }

        let omittedPatchCount = zip(selectedFiles, files).filter { original, snapshot in
            original.patch != nil && snapshot.patch == nil
        }.count
        if omittedPatchCount > 0 {
            omissions.append("\(omittedPatchCount) selected text patches were omitted after the request's patch budget was reached.")
        }

        let truncatedPatchCount = zip(selectedFiles, files).filter { original, snapshot in
            guard let originalPatch = original.patch, let suppliedPatch = snapshot.patch else { return false }
            return originalPatch.count > suppliedPatch.count
        }.count
        if truncatedPatchCount > 0 {
            omissions.append("\(truncatedPatchCount) text patches were truncated. Do not infer behavior beyond the provided hunks.")
        }

        let noteContexts = annotations.prefix(20).map {
            AIAnnotationContext(annotation: $0).boundedForPrompt()
        }

        if annotations.count > noteContexts.count {
            omissions.append("Only \(noteContexts.count) of \(annotations.count) review notes were included.")
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
            description: details.body,
            commits: commitContexts,
            selectedPaths: selected.sorted(),
            fileInventory: inventory,
            files: files,
            annotations: noteContexts,
            selectedAnnotationCount: annotations.count,
            omissions: omissions,
            pullRequestConversation: details.conversation.map(AICommentContext.init)
        )

    }
}
