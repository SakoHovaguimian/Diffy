import Foundation

protocol AICommitMessageServiceProtocol: Sendable {
    func isAvailable() async -> Bool
    func suggestMessage(for stagedPatch: String) async throws -> String
}

struct AICommitMessageService: AICommitMessageServiceProtocol {

    let apiProvider: any AIProvider
    let cliProvider: any AIProvider
    let settingsStore: any AISettingsStoreProtocol
    let credentialStore: any AICredentialStoreProtocol
    let commandAvailability: any AICommandAvailabilityServiceProtocol

    func isAvailable() async -> Bool {

        guard let settings = try? await self.settingsStore.loadSettings(),
              AIModelIdentifier.isValid(settings.defaultModel) else { return false }

        switch settings.defaultRoute {

        case .providerAPI:
            return await self.credentialStore.hasAPIKey(for: settings.defaultProvider)

        case .installedCLI:
            return await self.commandAvailability.availability(for: settings.defaultProvider).isAvailable

        }

    }

    func suggestMessage(for stagedPatch: String) async throws -> String {

        guard !stagedPatch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIReviewError.unavailable("Stage changes before asking AI for a commit message.")
        }

        let settings = try await self.settingsStore.loadSettings()
        guard await self.isAvailable() else {
            throw AIReviewError.unavailable("Set up AI in Settings → AI Review to suggest a commit message.")
        }

        let context = AIReviewContext(
            repositoryIdentity: "",
            pullRequestNumber: 0,
            title: "",
            author: "",
            baseSHA: "",
            headSHA: "",
            description: "",
            commits: [],
            selectedPaths: [],
            fileInventory: [],
            files: [],
            annotations: [],
            selectedAnnotationCount: 0,
            omissions: [],
            pullRequestConversation: nil
        )
        let request = AIRequest(
            provider: settings.defaultProvider,
            model: settings.defaultModel,
            context: context,
            systemPrompt: AIReviewPrompts.systemPrompt(for: .commitMessage),
            userPrompt: "Staged patch:\n\(String(stagedPatch.prefix(20_000)))",
            schema: .commitMessage,
            maxOutputTokens: 120
        )
        let provider = settings.defaultRoute == .providerAPI ? self.apiProvider : self.cliProvider
        let suggestion = try await provider.generate(request: request, responseType: AICommitMessageSuggestion.self)
        let message = suggestion.message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !message.isEmpty, !message.contains("\n"), message.count <= 72 else {
            throw AIReviewError.invalidResponse("The suggested subject must be one short line.")
        }

        return message

    }

}
