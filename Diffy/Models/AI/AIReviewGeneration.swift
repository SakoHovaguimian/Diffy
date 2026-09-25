import Foundation

struct AIReviewGeneration: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let repositoryIdentity: String
    let pullRequestNumber: Int
    let visualizationType: AIVisualization
    let provider: AIProviderKind
    let model: String
    let route: AIExecutionRoute
    let createdAt: Date
    let baseSHA: String
    let headSHA: String
    let userPrompt: String
    let structuredOutput: AIReviewOutput
    let context: AIReviewContext
    let analyzedFiles: [AIFileSnapshot]

    var hasConsistentContext: Bool {

        self.context.repositoryIdentity == self.repositoryIdentity
            && self.context.pullRequestNumber == self.pullRequestNumber
            && self.context.baseSHA == self.baseSHA
            && self.context.headSHA == self.headSHA
            && self.structuredOutput.visualizationType == self.visualizationType

    }

    func isCurrent(baseSHA: String, headSHA: String) -> Bool {
        self.baseSHA == baseSHA && self.headSHA == headSHA
    }
}
