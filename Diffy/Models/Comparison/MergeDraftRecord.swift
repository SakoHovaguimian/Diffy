import Foundation

/// A recoverable, per-project merge draft kept in Diffy's Application Support area,
/// never inside the repository.
struct MergeDraftRecord: Codable, Hashable, Sendable {
    let projectID: String
    let path: String
    let sourceFingerprint: String
    let results: [Int: String]
    let decisions: [Int: MergeDecision]
    let savedAt: Date
}
