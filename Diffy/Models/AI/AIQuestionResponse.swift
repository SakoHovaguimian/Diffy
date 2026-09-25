import Foundation

struct AIQuestionResponse: Codable, Hashable, Sendable {
    let answer: String
    let relevantFiles: [String]
    let evidence: [String]
    let uncertainty: String
}
