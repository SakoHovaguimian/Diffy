import Foundation

struct AICommitContext: Codable, Hashable, Sendable {
    let sha: String
    let title: String
    let author: String
}
