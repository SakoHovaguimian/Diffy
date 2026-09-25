import Foundation

struct CodeAnnotation: Identifiable, Codable, Hashable {

    let id: UUID
    let projectID: String
    let projectName: String
    let comparison: String
    let filePath: String
    let source: String
    let side: SourceSide
    let startLine: Int
    let endLine: Int
    let snippet: String
    let language: String
    let createdAt: Date
    var comment: String
    var isResolved: Bool
    var comparisonMode: String? = nil

}
