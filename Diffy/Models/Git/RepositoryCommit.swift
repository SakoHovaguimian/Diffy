import Foundation

struct RepositoryCommit: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let authorName: String
    let authoredAt: Date
    let parentIDs: [String]
    var additions: Int?
    var deletions: Int?

    var shortID: String {
        String(self.id.prefix(7))
    }

    var isMergeCommit: Bool {
        self.parentIDs.count > 1
    }
}
