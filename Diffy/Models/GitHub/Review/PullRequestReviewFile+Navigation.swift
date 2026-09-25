import Foundation

extension PullRequestReviewFile {

    /// Summary data for the shared navigator; GitHub does not supply disk metadata.
    var navigationFile: DiffFile {

        DiffFile(
            id: self.id,
            path: self.filename,
            originalPath: self.previousFilename,
            status: self.changeStatus,
            kind: .text,
            isStaged: false,
            lastEditedAt: nil,
            size: 0,
            lines: [],
            lineCounts: DiffLineCounts(additions: self.additions, deletions: self.deletions),
            isContentLoaded: false
        )

    }

    private var changeStatus: FileChangeStatus {

        switch self.status {

        case "added", "copied": .added
        case "removed": .removed
        case "renamed": .renamed
        case "unchanged": .identical
        default: .modified

        }

    }

}
