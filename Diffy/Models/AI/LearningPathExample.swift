import Foundation

struct LearningPathExample: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let kind: LearningPathExampleKind
    let language: String
    let code: String
    let explanation: String
    let filePath: String
}
