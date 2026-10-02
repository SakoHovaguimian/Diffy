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

        fileComments(in: file).filter { entry in

            let location = conversationLocation(for: entry)
            return location.line != nil && location.line == (location.side == "LEFT" ? line.oldNumber : line.newNumber)

        }

    }

    func unanchoredComments(in file: PullRequestReviewFile, lines: [DiffLine]) -> [PullRequestConversationEntry] {

        let oldNumbers = Set(lines.compactMap(\.oldNumber))
        let newNumbers = Set(lines.compactMap(\.newNumber))

        return fileComments(in: file).filter { comment in

            let location = conversationLocation(for: comment)
            guard let number = location.line else { return true }
            return !(location.side == "LEFT" ? oldNumbers : newNumbers).contains(number)

        }

    }

    func discussionLineIDs(in file: PullRequestReviewFile, lines: [DiffLine]) -> Set<Int> {

        var oldNumbers: Set<Int> = []
        var newNumbers: Set<Int> = []

        for draft in self.drafts where draft.path == file.filename {

            if draft.side == "LEFT" {
                oldNumbers.insert(draft.line)
            } else {
                newNumbers.insert(draft.line)
            }

        }

        for comment in fileComments(in: file) {

            let location = conversationLocation(for: comment)
            guard let number = location.line else { continue }
            if location.side == "LEFT" {
                oldNumbers.insert(number)
            } else {
                newNumbers.insert(number)
            }

        }

        return Set(lines.compactMap { line in

            let hasOldDiscussion = line.oldNumber.map { oldNumbers.contains($0) } ?? false
            let hasNewDiscussion = line.newNumber.map { newNumbers.contains($0) } ?? false
            return hasOldDiscussion || hasNewDiscussion ? line.id : nil

        })

    }

    private func fileComments(in file: PullRequestReviewFile) -> [PullRequestConversationEntry] {

        self.conversation.filter { entry in

            let path = conversationLocation(for: entry).path
            return entry.kind == .inline && (path == file.filename || (file.previousFilename != nil && path == file.previousFilename))

        }

    }

}
