import Foundation

struct AIConversationEntry: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let repositoryIdentity: String
    let pullRequestNumber: Int
    let createdAt: Date
    let baseSHA: String
    let headSHA: String
    let provider: AIProviderKind
    let model: String
    let route: AIExecutionRoute
    let userPrompt: String
    let annotationIDs: [UUID]
    let analyzedNotes: [AIAnnotationContext]
    let analyzedFiles: [AIFileSnapshot]
    let context: AIReviewContext
    let output: AIConversationOutput

    var hasConsistentContext: Bool {

        self.context.repositoryIdentity == self.repositoryIdentity
            && self.context.pullRequestNumber == self.pullRequestNumber
            && self.context.baseSHA == self.baseSHA
            && self.context.headSHA == self.headSHA

    }
}
