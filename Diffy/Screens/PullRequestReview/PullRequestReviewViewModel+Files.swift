import Foundation

@MainActor
extension PullRequestReviewViewModel {

    var selectedReviewFile: PullRequestReviewFileViewModel? {
        self.reviewFiles.first { $0.id == self.selectedFileID }
    }

    var reviewEntries: [FileTreeEntry] {
        self.fileNavigator.entries(Array(self.visibleFiles.prefix(self.visibleLimit)).map(\.navigationFile), mode: .pullRequests)
    }

    var counts: DiffLineCounts {

        let files = self.details?.files ?? []
        return DiffLineCounts(
            additions: files.reduce(0) { $0 + $1.additions },
            deletions: files.reduce(0) { $0 + $1.deletions }
        )

    }

    func reviewFile(for id: String) -> PullRequestReviewFileViewModel? {
        self.reviewFiles.first { $0.id == id }
    }

    func markViewed(_ viewed: Bool, file: PullRequestReviewFile) {

        if viewed {
            self.viewedPaths.insert(file.id)
        } else {
            self.viewedPaths.remove(file.id)
        }
        self.reviewFile(for: file.id)?.isExpanded = !viewed

    }

    func expandShown() {
        self.reviewEntries.compactMap(\.file).forEach { self.reviewFile(for: $0.id)?.isExpanded = true }
    }

    func collapseAll() {
        self.reviewFiles.forEach { $0.isExpanded = false }
    }

    func clearFileFilters() {

        self.fileNavigator.clearFilters()
        self.onlyUnviewed = false

    }

    // MARK: - File Discussions

    func drafts(at line: DiffLine, in file: PullRequestReviewFile) -> [PullRequestReviewCommentDraft] {
        self.drafts.filter { $0.path == file.filename && $0.line == ($0.side == "LEFT" ? line.oldNumber : line.newNumber) }
    }

    func comments(at line: DiffLine, in file: PullRequestReviewFile) -> [PullRequestConversationEntry] {
        fileComments(in: file).filter { $0.line != nil && $0.line == ($0.side == "LEFT" ? line.oldNumber : line.newNumber) }
    }

    func unanchoredComments(in file: PullRequestReviewFile, lines: [DiffLine]) -> [PullRequestConversationEntry] {

        fileComments(in: file).filter { comment in
            !lines.contains { line in
                comment.line != nil && comment.line == (comment.side == "LEFT" ? line.oldNumber : line.newNumber)
            }
        }

    }

    func discussionLineIDs(in file: PullRequestReviewFile, lines: [DiffLine]) -> Set<Int> {
        Set(lines.filter { !self.drafts(at: $0, in: file).isEmpty || !self.comments(at: $0, in: file).isEmpty }.map(\.id))
    }

    private func fileComments(in file: PullRequestReviewFile) -> [PullRequestConversationEntry] {
        self.conversation.filter { $0.kind == .inline && $0.path == file.filename }
    }

}
