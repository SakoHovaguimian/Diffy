import Foundation

struct MockAIModelCatalogService: AIModelCatalogServiceProtocol {

    func models(for provider: AIProviderKind, route: AIExecutionRoute) async throws -> AIModelCatalog {

        let models: [String]

        switch route {

        case .providerAPI:
            models = AISettings.initial.models(for: provider, route: route)

        case .installedCLI:
            switch provider {

            case .openAI: models = ["gpt-6-sol"]
            case .anthropic: models = ["claude-sonnet-5"]
            case .gemini: models = ["auto"]

            }

        }
        return AIModelCatalog(
            modelIDs: models,
            recommendedModelID: models.first,
            sourceDescription: "Preview model examples",
            notice: "These preview models do not reflect installed tools or account access."
        )

    }
}
