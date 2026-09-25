import Foundation

struct OverviewProjectChange: Identifiable {
    let project: RepositoryProject
    let branchName: String
    let changedFileCount: Int
    let lineCounts: DiffLineCounts?
    let hasConflicts: Bool

    var id: String {
        self.project.id
    }
}
