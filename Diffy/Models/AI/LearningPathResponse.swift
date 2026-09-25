import Foundation

struct LearningPathResponse: Codable, Hashable, Sendable {
    let title: String
    let overview: String
    let steps: [LearningPathStep]
}
