import Foundation

struct LiveAIModelCatalogService: AIModelCatalogServiceProtocol {

    let credentialStore: any AICredentialStoreProtocol

    func models(for provider: AIProviderKind, route: AIExecutionRoute) async throws -> AIModelCatalog {

        switch route {

        case .providerAPI:
            return try await LiveAPIModelCatalogService(credentialStore: self.credentialStore).models(for: provider)

        case .installedCLI:
            return try await LiveCLIModelCatalogService().models(for: provider)

        }

    }
}
