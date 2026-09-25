import Foundation

struct DiffFile: Codable, Identifiable, Hashable, Sendable {

    let id: String
    let path: String
    let originalPath: String?
    let status: FileChangeStatus
    let kind: ComparisonFileKind
    let isStaged: Bool
    let lastEditedAt: Date?
    let size: Int
    let lines: [DiffLine]

    /// Summary counts from a listing, used before a file's lines are loaded.
    var lineCounts: DiffLineCounts?

    /// Live listings load each file's lines on demand. Fixtures are always loaded.
    var isContentLoaded: Bool = true

    var name: String {
        (self.path as NSString).lastPathComponent
    }

    var directory: String {
        (self.path as NSString).deletingLastPathComponent
    }

    var updatedMinutesAgo: Int {

        guard let lastEditedAt = self.lastEditedAt else {
            return .max
        }

        return max(0, Int(Date().timeIntervalSince(lastEditedAt) / 60))

    }

    var hasNoOriginalSource: Bool {
        self.status == .added && self.lines.allSatisfy { $0.left == nil }
    }

    var originalSource: String {
        self.lines.compactMap(\.left).joined(separator: "\n")
    }

    var updatedSource: String {
        self.lines.compactMap(\.right).joined(separator: "\n")
    }

    var additions: Int {

        guard self.isContentLoaded else {
            return self.lineCounts?.additions ?? 0
        }

        return self.lines.filter { $0.status == .added }.count

    }

    var deletions: Int {

        guard self.isContentLoaded else {
            return self.lineCounts?.deletions ?? 0
        }

        return self.lines.filter { $0.status == .removed }.count

    }

    var changedLines: Int {
        self.lines.filter { $0.status == .modified }.count
    }

    var changeMagnitude: Int {

        if let lineCounts = self.lineCounts {
            return lineCounts.additions + lineCounts.deletions
        }

        return self.additions + self.deletions + self.changedLines

    }

    var language: String {

        switch (self.path as NSString).pathExtension {

        case "swift": "swift"
        case "ts": "typescript"
        case "json": "json"
        case "md": "markdown"
        default: "text"

        }

    }

    func replacingLines(_ lines: [DiffLine]) -> DiffFile {
        replacingContent(lines: lines, kind: self.kind)
    }

    func replacingContent(lines: [DiffLine], kind: ComparisonFileKind) -> DiffFile {

        var file = DiffFile(
            id: self.id,
            path: self.path,
            originalPath: self.originalPath,
            status: self.status,
            kind: kind,
            isStaged: self.isStaged,
            lastEditedAt: self.lastEditedAt,
            size: self.size,
            lines: lines
        )
        file.lineCounts = self.lineCounts

        return file

    }

    /// A listing entry suitable for the launch cache: summary data without source lines.
    func withoutContent() -> DiffFile {

        var file = replacingLines([])
        file.lineCounts = DiffLineCounts(additions: self.additions, deletions: self.deletions)
        file.isContentLoaded = false

        return file

    }

}
