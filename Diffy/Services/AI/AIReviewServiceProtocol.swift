import Foundation

protocol AIReviewServiceProtocol: Sendable {
    func generate(
        visualization: AIVisualization,
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute,
        userPrompt: String
    ) async throws -> AIReviewOutput

    func ask(
        question: String,
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute
    ) async throws -> AIQuestionResponse

    func addressNotes(
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute
    ) async throws -> AINoteFixResponse
}
