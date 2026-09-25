import Foundation

protocol AICommandAvailabilityServiceProtocol: Sendable {
    func availability(for provider: AIProviderKind) async -> AICommandAvailability
}
