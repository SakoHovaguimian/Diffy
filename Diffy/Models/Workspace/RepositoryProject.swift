import Foundation

struct RepositoryProject: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let bucketID: String
    let symbol: String
    let branch: String
    let language: String
    let updatedLabel: String
    let files: [DiffFile]
    let commits: [MockCommit]
    let directoryPath: String?

    var changeCount: Int {
        self.files.filter { $0.status != .identical }.count
    }
}
