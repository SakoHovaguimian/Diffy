import Foundation

enum GitOutputParser {

    static func changes(_ output: String) -> [GitFileChange] {

        let fields = output.split(separator: "\0", omittingEmptySubsequences: true).map(String.init)
        var changes: [GitFileChange] = []
        var index = 0

        while index < fields.count {

            let entry = fields[index]
            index += 1

            guard entry.count >= 3 else {
                continue
            }

            let columns = Array(entry.prefix(2))
            let path = String(entry.dropFirst(3))
            let isRename = columns.contains("R") || columns.contains("C")
            let original = isRename && index < fields.count ? fields[index] : nil

            if original != nil {
                index += 1
            }

            changes.append(GitFileChange(
                path: path,
                originalPath: original,
                indexStatus: status(columns[0]),
                worktreeStatus: status(columns[1]),
                conflict: conflict(String(columns))
            ))

        }

        return changes

    }

    static func status(_ code: Character) -> GitFileStatusCode {

        switch code {

        case "M": .modified
        case "T": .fileTypeChanged
        case "A": .added
        case "D": .deleted
        case "R": .renamed
        case "C": .copied
        case "U": .unmerged
        case "?": .untracked
        case "!": .ignored
        default: .unmodified

        }

    }

    private static func conflict(_ code: String) -> GitConflictKind? {

        switch code {

        case "UU": .bothModified
        case "AA": .bothAdded
        case "DD": .bothDeleted
        case "AU": .addedByUs
        case "UA": .addedByThem
        case "DU": .deletedByUs
        case "UD": .deletedByThem
        default: nil

        }

    }

    static func commits(_ output: String) -> [RepositoryCommit] {

        output.split(separator: "\0").compactMap { record in

            let fields = record.trimmingCharacters(in: .newlines).components(separatedBy: "\u{1f}")

            guard fields.count == 5, let timestamp = Double(fields[3]) else {
                return nil
            }

            return RepositoryCommit(
                id: fields[0],
                title: fields[4],
                authorName: fields[2],
                authoredAt: Date(timeIntervalSince1970: timestamp),
                parentIDs: fields[1].split(separator: " ").map(String.init)
            )

        }

    }

    static func branches(_ output: String) -> [RepositoryBranch] {

        output.split(separator: "\n").compactMap { record in

            let fields = record.components(separatedBy: "\0")

            guard fields.count >= 5, !fields[0].hasSuffix("/HEAD") else {
                return nil
            }

            let remote = fields[0].hasPrefix("refs/remotes/")
            let prefix = remote ? "refs/remotes/" : "refs/heads/"

            return RepositoryBranch(
                name: String(fields[0].dropFirst(prefix.count)),
                isRemote: remote,
                commitID: fields[1],
                upstreamName: fields[2].isEmpty ? nil : fields[2],
                isCurrent: fields[3] == "*",
                lastCommitAt: Double(fields[4]).map { Date(timeIntervalSince1970: $0) }
            )

        }

    }

}
