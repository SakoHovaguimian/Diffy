import Foundation

protocol AIReviewServiceProtocol: Sendable {
    func generate(
        visualization: AIVisualization,
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute,
        userPrompt: String,
        progress: @escaping @MainActor @Sendable (String) async -> Void
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
