import Foundation

struct LiveCLIModelCatalogService: Sendable {

    func models(for provider: AIProviderKind) async throws -> AIModelCatalog {

        let locator = InstalledAICommandLocator()
        guard let executable = locator.executable(for: provider) else {
            throw AICommandError.unavailable(provider.commandTitle)
        }

        switch provider {

        case .openAI:
            return try await CodexCLIModelCatalogService().models(executable: executable, environment: locator.environment)

        case .anthropic:
            return try await ClaudeCLIModelCatalogService().models(executable: executable, environment: locator.environment)

        case .gemini:
            return try await GeminiCLIModelCatalogService().models(executable: executable, environment: locator.environment)

        }

    }
}
