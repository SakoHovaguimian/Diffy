import Foundation

final class AIReviewService: AIReviewServiceProtocol {

    private let apiProvider: any AIProvider
    private let cliProvider: any AIProvider

    init(
        apiProvider: any AIProvider,
        cliProvider: any AIProvider
    ) {

        self.apiProvider = apiProvider
        self.cliProvider = cliProvider

    }

    func generate(
        visualization: AIVisualization,
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute,
        userPrompt: String
    ) async throws -> AIReviewOutput {

        let schema = self.schema(for: visualization)
        let request = try self.request(
            schema: schema,
            context: context,
            provider: provider,
            model: model,
            userPrompt: userPrompt
        )
        let selectedProvider = self.provider(for: route)
        let output: AIReviewOutput

        switch visualization {

        case .learningPath:
            let response = try await selectedProvider.generate(request: request, responseType: LearningPathResponse.self)
            output = .learningPath(response)

        case .architectureMap:
            let response = try await selectedProvider.generate(request: request, responseType: ArchitectureMapResponse.self)
            output = .architectureMap(response)

        case .riskMap:
            let response = try await selectedProvider.generate(request: request, responseType: RiskMapResponse.self)
            output = .riskMap(response)

        }

        try Task.checkCancellation()
        try AIOutputValidator.validate(output, context: context)
        return output

    }

    func ask(
        question: String,
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute
    ) async throws -> AIQuestionResponse {

        let request = try self.request(
            schema: .question,
            context: context,
            provider: provider,
            model: model,
            userPrompt: question
        )
        let response = try await self.provider(for: route).generate(request: request, responseType: AIQuestionResponse.self)
        try Task.checkCancellation()
        try AIOutputValidator.validate(response, context: context)
        return response

    }

    func addressNotes(
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute
    ) async throws -> AINoteFixResponse {

        guard !context.annotations.isEmpty else {
            throw AIReviewError.invalidResponse("Select review notes first.")
        }

        guard context.annotations.count == context.selectedAnnotationCount else {
            throw AIReviewError.unavailable("Select at most 20 review notes so every note is included.")
        }

        let request = try self.request(
            schema: .noteFix,
            context: context,
            provider: provider,
            model: model,
            userPrompt: "Propose a plan and patch addressing the selected review notes."
        )
        let response = try await self.provider(for: route).generate(request: request, responseType: AINoteFixResponse.self)
        try Task.checkCancellation()
        try AIOutputValidator.validate(response, context: context)
        return response

    }

    private func provider(for route: AIExecutionRoute) -> any AIProvider {
        route == .providerAPI ? self.apiProvider : self.cliProvider
    }

    private func schema(for visualization: AIVisualization) -> AIResponseSchema {

        switch visualization {

        case .learningPath: .learningPath
        case .architectureMap: .architectureMap
        case .riskMap: .riskMap

        }

    }

    private func request(
        schema: AIResponseSchema,
        context: AIReviewContext,
        provider: AIProviderKind,
        model: String,
        userPrompt: String
    ) throws -> AIRequest {

        let prompt = """
        User request: \(String(userPrompt.prefix(4_000)))

        PR context as JSON data for revision base=\(context.baseSHA), head=\(context.headSHA):
        \(try context.promptText())
        """

        return AIRequest(
            provider: provider,
            model: model,
            context: context,
            systemPrompt: AIReviewPrompts.systemPrompt(for: schema),
            userPrompt: prompt,
            schema: schema,
            maxOutputTokens: 8_000
        )

    }
}
