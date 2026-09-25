import Foundation

struct DiffFile: Identifiable, Hashable {

    let id: String
    let path: String
    let originalPath: String?
    let status: FileChangeStatus
    let kind: ComparisonFileKind
    let isStaged: Bool
    let updatedMinutesAgo: Int
    let size: Int
    let lines: [DiffLine]

    var name: String {
        (self.path as NSString).lastPathComponent
    }

    var directory: String {
        (self.path as NSString).deletingLastPathComponent
    }

    var hasNoOriginalSource: Bool {
        self.status == .added && self.lines.allSatisfy { $0.left == nil }
    }

    var additions: Int {
        self.lines.filter { $0.status == .added }.count
    }

    var deletions: Int {
        self.lines.filter { $0.status == .removed }.count
    }

    var changedLines: Int {
        self.lines.filter { $0.status == .modified }.count
    }

    var changeMagnitude: Int {
        self.additions + self.deletions + self.changedLines
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

}
