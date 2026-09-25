import Foundation

/// The patch sent to AI is retained with its result so an older generation never
/// has to borrow the current PR's diff for file navigation.
struct AIFileSnapshot: Codable, Hashable, Identifiable, Sendable {
    let filename: String
    let previousFilename: String?
    let status: String
    let additions: Int
    let deletions: Int
    let patch: String?

    var id: String { self.filename }
}
