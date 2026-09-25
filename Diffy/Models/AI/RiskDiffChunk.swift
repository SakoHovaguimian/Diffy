import Foundation

struct RiskDiffChunk: Codable, Sendable {
    let id: String
    let path: String
    let part: Int
    let totalParts: Int
    let status: String
    let additions: Int
    let deletions: Int
    let text: String
}
