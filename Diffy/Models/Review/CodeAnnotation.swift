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
    var priority: AnnotationPriority? = nil
    var acceptanceCriteria: String? = nil
    var updatedAt: Date? = nil
    var needsReviewReason: AnnotationReviewReason? = nil
    var needsReviewSince: Date? = nil
    var reviewTargetSource: String? = nil
    var lastReviewedSource: String? = nil

    var needsReview: Bool {
        !self.isResolved && self.needsReviewReason != nil
    }

}
