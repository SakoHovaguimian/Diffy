import Foundation

struct PullRequestNoteDraft: Identifiable {
    let id = UUID()
    let filePath: String
    let line: Int
    let side: SourceSide
    let snippet: String
    let language: String
    let source: String
    let baseSHA: String
    let headSHA: String
}
