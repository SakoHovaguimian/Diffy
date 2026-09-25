import Foundation

struct MockAICommandAvailabilityService: AICommandAvailabilityServiceProtocol {

    func availability(for provider: AIProviderKind) async -> AICommandAvailability {

        AICommandAvailability(
            provider: provider,
            executablePath: nil,
            problem: "Installed tools are available in Diffy Live. Mock & previews never run local commands."
        )

    }

}
