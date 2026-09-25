import Foundation

struct AIRequest: Sendable {
    let provider: AIProviderKind
    let model: String
    let context: AIReviewContext
    let systemPrompt: String
    let userPrompt: String
    let schema: AIResponseSchema
    let maxOutputTokens: Int
}
