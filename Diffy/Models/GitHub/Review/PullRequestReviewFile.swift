import Foundation

struct PullRequestReviewFile: Decodable, Identifiable, Sendable {
    let filename: String
    let previousFilename: String?
    let status: String
    let additions: Int
    let deletions: Int
    let patch: String?
    let blobUrl: URL?

    var id: String { self.filename }

    var hasCompletePatch: Bool {

        guard let patch else { return false }
        let counts = GitPatchParser.lineCounts(patch)
        return counts.additions == self.additions && counts.deletions == self.deletions

    }
}
