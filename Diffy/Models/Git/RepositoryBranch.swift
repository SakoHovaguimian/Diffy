import Foundation

struct RepositoryBranch: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let isRemote: Bool
    let commitID: String
    var upstreamName: String?
    var ahead: Int?
    var behind: Int?
    var isCurrent: Bool = false
    var lastCommitAt: Date?

    var id: String {
        (self.isRemote ? "remote/" : "local/") + self.name
    }
}
