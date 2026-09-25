import Foundation

struct RepositoryPathEntry: Identifiable, Hashable, Sendable {
    let path: String
    let gitUpdatedAt: Date?
    let diskUpdatedAt: Date?
    let isTracked: Bool
    var prefersDiskTime = false
    var status: FileChangeStatus?

    var id: String { self.path }
    var lastUpdatedAt: Date? {
        self.prefersDiskTime ? (self.diskUpdatedAt ?? self.gitUpdatedAt) : (self.gitUpdatedAt ?? self.diskUpdatedAt)
    }

    var updateLabel: String {

        if self.prefersDiskTime, let diskUpdatedAt {
            return "\(self.isTracked ? "Disk modified" : "No Git history · disk modified") \(diskUpdatedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        if let gitUpdatedAt {
            return "Git updated \(gitUpdatedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        if let diskUpdatedAt {
            return "\(self.isTracked ? "Git recency unavailable" : "No Git history") · disk modified \(diskUpdatedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        return self.isTracked ? "Git recency unavailable" : "No Git history"

    }
}
