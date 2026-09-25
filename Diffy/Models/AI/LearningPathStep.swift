import Foundation

struct LearningPathStep: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let whyItMatters: String
    let relevantFiles: [String]
    let relevantSymbols: [String]
    let suggestedFiles: [String]
    let dependsOn: [String]
}
