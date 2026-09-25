import Foundation

struct DiffRegion: Identifiable {
    let id: Int
    let lines: [DiffLine]
    let isChanged: Bool

    var status: FileChangeStatus {
        self.lines.first?.status ?? .identical
    }

    var originalCount: Int {
        self.lines.filter { $0.left != nil }.count
    }

    var updatedCount: Int {
        self.lines.filter { $0.right != nil }.count
    }
}
