import Foundation

protocol AIModelCatalogServiceProtocol: Sendable {
    func models(for provider: AIProviderKind, route: AIExecutionRoute) async throws -> AIModelCatalog
}
