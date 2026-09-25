import Foundation

struct OverviewProjectChange: Identifiable, Sendable {
    let project: RepositoryProject
    let branchName: String
    let changedFileCount: Int
    let lineCounts: DiffLineCounts?
    let hasConflicts: Bool
    var upstream: GitUpstreamStatus?
    var lastFetchAt: Date?

    var id: String {
        self.project.id
    }
}
