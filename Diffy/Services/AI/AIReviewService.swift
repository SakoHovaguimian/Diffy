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
        userPrompt: String,
        progress: @escaping @MainActor @Sendable (String) async -> Void
    ) async throws -> AIReviewOutput {

        if visualization == .riskMap {

            let response = try await self.generateRiskMap(
                context: context,
                provider: self.provider(for: route),
                providerKind: provider,
                model: model,
                userPrompt: userPrompt,
                progress: progress
            )
            let output = AIReviewOutput.riskMap(response)
            try AIOutputValidator.validate(output, context: context)
            return output

        }

        let schema = self.schema(for: visualization)
        let request = try self.request(
            schema: schema,
            context: context,
            provider: provider,
            model: model,
            userPrompt: userPrompt
        )
        let selectedProvider = self.provider(for: route)
        let output = try await self.generateOutput(
            visualization: visualization,
            request: request,
            provider: selectedProvider
        )
        try Task.checkCancellation()

        let unavailablePaths = self.unavailablePatchPaths(in: output, context: context)
        if !unavailablePaths.isEmpty {

            let retryPrompt = request.userPrompt + """

            Regenerate the complete response. These paths in the previous draft had no supplied patch:
            \(unavailablePaths.joined(separator: "\n"))
            Use only the listed patch paths in changedFiles or risk files.
            """
            let retryRequest = AIRequest(
                provider: request.provider,
                model: request.model,
                context: request.context,
                systemPrompt: request.systemPrompt,
                userPrompt: retryPrompt,
                schema: request.schema,
                maxOutputTokens: request.maxOutputTokens
            )
            let retryOutput = try await self.generateOutput(
                visualization: visualization,
                request: retryRequest,
                provider: selectedProvider
            )
            try Task.checkCancellation()
            try AIOutputValidator.validate(retryOutput, context: context)
            return retryOutput

        }

        try AIOutputValidator.validate(output, context: context)
        return output

    }

    private func generateOutput(
        visualization: AIVisualization,
        request: AIRequest,
        provider: any AIProvider
    ) async throws -> AIReviewOutput {

        switch visualization {

        case .learningPath:
            let response = try await provider.generate(request: request, responseType: LearningPathResponse.self)
            return .learningPath(response)

        case .architectureMap:
            let response = try await provider.generate(request: request, responseType: ArchitectureMapResponse.self)
            return .architectureMap(response)

        case .riskMap:
            let response = try await provider.generate(request: request, responseType: RiskMapResponse.self)
            return .riskMap(response)

        }

    }

    private func unavailablePatchPaths(in output: AIReviewOutput, context: AIReviewContext) -> [String] {

        let citedPaths: [String]

        switch output {

        case .learningPath:
            return []

        case .architectureMap(let response):
            citedPaths = response.nodes.flatMap(\.changedFiles)

        case .riskMap(let response):
            citedPaths = response.risks.flatMap(\.files)

        }

        return Set(citedPaths).subtracting(context.patchPaths).sorted()

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
        \(self.patchPathInstruction(schema: schema, context: context))
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

    private func patchPathInstruction(schema: AIResponseSchema, context: AIReviewContext) -> String {

        guard schema == .architectureMap || schema == .riskMap else { return "" }
        let paths = context.patchPaths.sorted()
        let list = paths.isEmpty ? "None. Use empty changedFiles arrays or an empty risks array." : paths.joined(separator: "\n")
        return "Paths with supplied patches that may be cited as changed files or risks:\n\(list)"

    }
}
