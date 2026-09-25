import Foundation
import Combine

@MainActor
final class AISettingsViewModel: ViewModel {

    let loggerName = "AI_SETTINGS_VIEW_MODEL"
    private let settingsStore: any AISettingsStoreProtocol
    private let credentialStore: any AICredentialStoreProtocol
    private let commandAvailability: any AICommandAvailabilityServiceProtocol
    private let modelCatalog: any AIModelCatalogServiceProtocol
    let usesPersistentStorage: Bool

    @Published var settings = AISettings.initial
    @Published var selectedProvider: AIProviderKind = .openAI {

        didSet {

            guard self.hasLoaded else { return }
            self.captureModelChoices(for: oldValue, route: self.selectedRoute)
            self.updateProviderEditor()
            self.refreshModels()

        }

    }
    @Published var selectedRoute: AIExecutionRoute = .providerAPI {

        didSet {

            guard self.hasLoaded else { return }
            self.captureModelChoices(for: self.selectedProvider, route: oldValue)
            self.updateProviderEditor()
            self.refreshModels()

        }

    }
    @Published var apiKeyDraft = ""
    @Published var showsAPIKey = false
    @Published var modelsText = ""
    @Published private(set) var savedKeyProviders = Set<AIProviderKind>()
    @Published private(set) var installedCommands: [AIProviderKind: AICommandAvailability] = [:]
    @Published private(set) var isBusy = false
    @Published private(set) var isDiscoveringModels = false
    @Published private(set) var modelSource: String?
    @Published private(set) var modelNotice: String?
    @Published private(set) var modelError: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var notice: String?
    private var hasLoaded = false
    private var savedBaseline = AISettings.initial
    private var modelDiscoveryToken = 0
    private var modelDiscoveryTask: Task<Void, Never>?

    init(
        settingsStore: any AISettingsStoreProtocol,
        credentialStore: any AICredentialStoreProtocol,
        commandAvailability: any AICommandAvailabilityServiceProtocol,
        modelCatalog: any AIModelCatalogServiceProtocol,
        usesPersistentStorage: Bool
    ) {

        self.settingsStore = settingsStore
        self.credentialStore = credentialStore
        self.commandAvailability = commandAvailability
        self.modelCatalog = modelCatalog
        self.usesPersistentStorage = usesPersistentStorage

    }

    // MARK: - Settings

    func load() async {

        guard !self.hasLoaded, !self.isBusy else { return }
        self.isBusy = true
        defer { self.isBusy = false }

        do {

            self.settings = try await self.settingsStore.loadSettings()
            self.savedBaseline = self.settings
            self.selectedProvider = self.settings.defaultProvider
            self.selectedRoute = self.settings.defaultRoute
            self.updateProviderEditor()
            self.hasLoaded = true
            await self.refreshAvailability()
            self.refreshModels()

        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func selectDefaultProvider() {

        if self.selectedProvider != self.settings.defaultProvider {
            self.selectedProvider = self.settings.defaultProvider
        }
        if self.selectedRoute != self.settings.defaultRoute {
            self.selectedRoute = self.settings.defaultRoute
        }

        let choices = self.settings.models(for: self.settings.defaultProvider, route: self.settings.defaultRoute)

        if !choices.contains(self.settings.defaultModel) {
            self.settings.defaultModel = choices.first ?? ""
        }
        self.refreshModels()

    }

    func updateProviderEditor() {

        self.apiKeyDraft = ""
        self.showsAPIKey = false
        self.modelsText = self.settings.models(for: self.selectedProvider, route: self.selectedRoute).joined(separator: "\n")
        self.notice = nil
        self.modelSource = nil
        self.modelNotice = nil
        self.modelError = nil

    }

    func saveSettings() async {

        guard !self.isBusy, !self.isDiscoveringModels else { return }
        self.isBusy = true
        self.errorMessage = nil
        self.notice = nil
        defer { self.isBusy = false }
        self.captureModelChoices(for: self.selectedProvider, route: self.selectedRoute)
        var updated = self.settings
        updated.defaultModel = updated.defaultModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let allModels = updated.availableModels.values.flatMap { $0 }
            + (updated.availableCLIModels ?? [:]).values.flatMap { $0 }

        guard AIModelIdentifier.isValid(updated.defaultModel), allModels.allSatisfy(AIModelIdentifier.isValid) else {

            self.errorMessage = "Use model IDs of 1–150 letters, numbers, dots, underscores, colons, or hyphens, starting with a letter or number. Claude models may also end in [1m]."
            return

        }

        if !updated.models(for: updated.defaultProvider, route: updated.defaultRoute).contains(updated.defaultModel) {
            var choices = updated.models(for: updated.defaultProvider, route: updated.defaultRoute)
            choices.append(updated.defaultModel)
            updated.setModels(choices, for: updated.defaultProvider, route: updated.defaultRoute)
        }

        do {

            let saved = try await self.settingsStore.updateSettings(updated, baseline: self.savedBaseline)
            self.settings = saved
            self.savedBaseline = saved
            self.modelsText = saved.models(for: self.selectedProvider, route: self.selectedRoute).joined(separator: "\n")
            self.notice = self.usesPersistentStorage
                ? "AI defaults and model choices are saved on this Mac."
                : "Demo AI settings are saved in memory for this session."

        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    // MARK: - Credentials & Installed Tools

    private func captureModelChoices(for provider: AIProviderKind, route: AIExecutionRoute) {

        let models = self.modelsText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        self.settings.setModels(Array(NSOrderedSet(array: models)).compactMap { $0 as? String }, for: provider, route: route)

    }

    func saveAPIKey() async {

        guard !self.isBusy, !self.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.isBusy = true
        self.errorMessage = nil
        self.notice = nil
        defer { self.isBusy = false }
        let provider = self.selectedProvider

        do {

            try await self.credentialStore.setAPIKey(self.apiKeyDraft, for: provider)
            self.apiKeyDraft = ""
            self.savedKeyProviders.insert(provider)
            self.notice = self.usesPersistentStorage
                ? "\(provider.title) API key saved in Keychain."
                : "Demo key saved in memory. Mock does not access Keychain."
            if self.selectedProvider == provider && self.selectedRoute == .providerAPI {
                self.refreshModels()
            }

        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func removeAPIKey() async {

        guard !self.isBusy else { return }
        self.isBusy = true
        self.errorMessage = nil
        self.notice = nil
        defer { self.isBusy = false }
        let provider = self.selectedProvider

        do {

            try await self.credentialStore.removeAPIKey(for: provider)
            self.apiKeyDraft = ""
            self.savedKeyProviders.remove(provider)
            self.notice = self.usesPersistentStorage
                ? "\(provider.title) API key removed from Keychain."
                : "Demo key removed from this session."

        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func refreshAvailability() async {

        for provider in AIProviderKind.allCases {

            let hasKey = await self.credentialStore.hasAPIKey(for: provider)

            if hasKey {
                self.savedKeyProviders.insert(provider)
            } else {
                self.savedKeyProviders.remove(provider)
            }

            self.installedCommands[provider] = await self.commandAvailability.availability(for: provider)

        }

    }

    // MARK: - Model Discovery

    func refreshModels() {

        self.modelDiscoveryTask?.cancel()
        self.modelDiscoveryToken += 1
        let token = self.modelDiscoveryToken
        let provider = self.selectedProvider
        let route = self.selectedRoute
        self.isDiscoveringModels = true
        self.modelError = nil
        self.modelNotice = nil
        self.modelDiscoveryTask = Task {
            await self.discoverModels(for: provider, route: route, token: token)
        }

    }

    private func discoverModels(for provider: AIProviderKind, route: AIExecutionRoute, token: Int) async {

        defer {
            if token == self.modelDiscoveryToken { self.isDiscoveringModels = false }
        }

        do {

            if route == .providerAPI {

                guard await self.credentialStore.hasAPIKey(for: provider) else {
                    throw AIReviewError.unavailable("Save a \(provider.title) API key in Keychain to fetch its models.")
                }

            } else {

                let availability = await self.commandAvailability.availability(for: provider)
                guard availability.isAvailable else {
                    throw AIReviewError.unavailable(availability.problem ?? "Install and sign in to the \(provider.title) command line tool to fetch its models.")
                }

            }

            let catalog = try await self.modelCatalog.models(for: provider, route: route)
            try Task.checkCancellation()
            guard token == self.modelDiscoveryToken,
                  self.selectedProvider == provider,
                  self.selectedRoute == route else { return }
            guard !catalog.modelIDs.isEmpty else {
                throw AIReviewError.unavailable("No models were returned. You can still enter a model ID manually.")
            }

            self.settings.setModels(catalog.modelIDs, for: provider, route: route)
            self.modelsText = catalog.modelIDs.joined(separator: "\n")
            self.modelSource = catalog.sourceDescription
            self.modelNotice = catalog.notice ?? "Found \(catalog.modelIDs.count) models. Save AI Settings to keep these choices."
            if self.settings.defaultProvider == provider && self.settings.defaultRoute == route,
               !catalog.modelIDs.contains(self.settings.defaultModel) {

                self.settings.defaultModel = catalog.recommendedModelID.flatMap { catalog.modelIDs.contains($0) ? $0 : nil }
                    ?? catalog.modelIDs[0]
                self.modelNotice = "Selected \(self.settings.defaultModel) for this connection. Save AI Settings to keep it."

            }

        } catch is CancellationError {
            return
        } catch {

            guard token == self.modelDiscoveryToken else { return }
            self.modelError = error.localizedDescription

        }

    }

}
