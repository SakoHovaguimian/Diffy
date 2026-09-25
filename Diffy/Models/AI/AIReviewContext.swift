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
    /// Nil in older saved generations; an empty array means a fetched conversation was empty.
    let pullRequestConversation: [AICommentContext]?

    var analyzedPaths: Set<String> {
        Set(self.fileInventory)
    }

    var patchPaths: Set<String> {
        Set(self.files.compactMap { file in
            guard let patch = file.patch, !patch.isEmpty else { return nil }
            return file.filename
        })
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

    func conversationPromptText() throws -> String {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(self.pullRequestConversation ?? [])
        guard let text = String(data: data, encoding: .utf8) else {
            throw AIReviewError.invalidResponse("The PR conversation could not be encoded.")
        }
        return text

    }
}
