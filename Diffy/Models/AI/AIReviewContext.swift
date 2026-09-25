import Foundation

struct AIReviewContext: Codable, Hashable, Sendable {
    let repositoryIdentity: String
    let pullRequestNumber: Int
    let title: String
    let author: String
    let baseSHA: String
    let headSHA: String
    let description: String
    let commits: [AICommitContext]
    let selectedPaths: [String]
    let fileInventory: [String]
    let files: [AIFileSnapshot]
    let annotations: [AIAnnotationContext]
    let selectedAnnotationCount: Int
    let omissions: [String]

    var analyzedPaths: Set<String> {
        Set(self.fileInventory)
    }

    var patchPaths: Set<String> {
        Set(self.files.compactMap { $0.patch == nil ? nil : $0.filename })
    }

    func promptText() throws -> String {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self)

        guard let text = String(data: data, encoding: .utf8) else {
            throw AIReviewError.invalidResponse("PR context could not be encoded.")
        }

        return text

    }
}
