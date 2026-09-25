import Foundation
import Combine

@MainActor
final class AIReviewWorkspaceViewModel: ViewModel {

    let loggerName = "AI_REVIEW_WORKSPACE_VIEW_MODEL"
    let request: PullRequestReviewRequest
    let repositoryIdentity: String
    private let reviewService: AIReviewServiceProtocol
    private let historyStore: AIHistoryStoreProtocol
    private let settingsStore: AISettingsStoreProtocol
    private let credentialStore: AICredentialStoreProtocol
    private let commandAvailability: AICommandAvailabilityServiceProtocol
    private let modelCatalog: AIModelCatalogServiceProtocol
    private let completeReviewFiles: @MainActor (PullRequestReviewDetails) async throws -> [AIFileSnapshot]
    private let loadReviewConversation: @MainActor () async throws -> [PullRequestConversationEntry]
    private var details: PullRequestReviewDetails?
    private var availableAnnotations: [CodeAnnotation] = []
    private var generationTask: Task<Void, Never>?
    private var questionTask: Task<Void, Never>?
    private var notesTask: Task<Void, Never>?
    private var modelDiscoveryTask: Task<Void, Never>?
    private var modelDiscoveryToken = 0
    private var settingsCache = AISettings.initial
    private var didLoadHistory = false
    private var hasLoadedSettings = false
    @Published private(set) var isLoadingHistory = false
    private var detailsRevision = 0
    private var hasInitializedAnnotations = false

    @Published private(set) var generations: [AIReviewGeneration] = []
    @Published private(set) var conversations: [AIConversationEntry] = []
    @Published private(set) var unsavedGenerations: [AIReviewGeneration] = []
    @Published private(set) var unsavedConversationEntries: [AIConversationEntry] = []
    @Published private(set) var proposedFixEntry: AIConversationEntry?
    @Published private(set) var commandStatus: AICommandAvailability?
    @Published private(set) var selectedAnnotationIDs: Set<UUID> = []
    @Published private var selectedGenerationIDs: [AIVisualization: UUID] = [:]
    @Published var requestedVisualization: AIVisualization?
    @Published var showsComposer = false
    @Published var selectedVisualization: AIVisualization = .learningPath
    @Published var selectedProvider: AIProviderKind = .openAI
    @Published var selectedModel = AISettings.initial.defaultModel
    @Published var selectedRoute: AIExecutionRoute = .providerAPI
    @Published var selectedPaths: Set<String> = []
    @Published private var expandedLearningStepIDs: [UUID: Set<String>] = [:]
    @Published var selectedArchitectureNodeID: String?
    @Published var selectedRiskID: String?
    @Published var selectedRiskFilePath: String?
    @Published var riskFileFilter: RiskAttention?
    @Published var fileQuery = ""
    @Published var showsFileSelection = false
    @Published var showsNotes = false
    @Published var showsApplyConfirmation = false
    @Published private(set) var pendingApplyEntry: AIConversationEntry?
    @Published var userPrompt = ""
    @Published var questionText = ""
    @Published private(set) var modelChoices = AISettings.initial.models(for: .openAI, route: .providerAPI)
    @Published private(set) var isDiscoveringModels = false
    @Published private(set) var modelLookupMessage: String?
    @Published private(set) var modelSource: String?
    @Published private(set) var modelNotice: String?
    @Published private(set) var modelError: String?
    @Published private(set) var isGenerating = false
    @Published private(set) var isAsking = false
    @Published private(set) var isAddressingNotes = false
    @Published private(set) var requestProgress: String?
    @Published var errorMessage: String?
    @Published var persistenceMessage: String?

    init(
        request: PullRequestReviewRequest,
        reviewService: AIReviewServiceProtocol,
        historyStore: AIHistoryStoreProtocol,
        settingsStore: AISettingsStoreProtocol,
        credentialStore: AICredentialStoreProtocol,
        commandAvailability: AICommandAvailabilityServiceProtocol,
        modelCatalog: AIModelCatalogServiceProtocol,
        completeReviewFiles: @escaping @MainActor (PullRequestReviewDetails) async throws -> [AIFileSnapshot],
        loadReviewConversation: @escaping @MainActor () async throws -> [PullRequestConversationEntry]
    ) {

        self.request = request
        self.repositoryIdentity = "\(request.link.host.lowercased())/\(request.link.fullName.lowercased())"
        self.reviewService = reviewService
        self.historyStore = historyStore
        self.settingsStore = settingsStore
        self.credentialStore = credentialStore
        self.commandAvailability = commandAvailability
        self.modelCatalog = modelCatalog
        self.completeReviewFiles = completeReviewFiles
        self.loadReviewConversation = loadReviewConversation

    }

    var hasAnyGeneration: Bool {
        !self.generations.isEmpty || !self.unsavedGenerations.isEmpty
    }

    var unsavedGeneration: AIReviewGeneration? { self.unsavedGenerations.first }
    var unsavedConversationEntry: AIConversationEntry? { self.unsavedConversationEntries.first }

    var availableFiles: [PullRequestReviewFile] {
        self.details?.files ?? []
    }

    var hasCurrentDetails: Bool { self.details != nil }

    var annotations: [CodeAnnotation] {
        self.availableAnnotations
    }

    var selectedAnnotations: [CodeAnnotation] {
        self.availableAnnotations.filter { self.selectedAnnotationIDs.contains($0.id) }
    }

    var isBusy: Bool {
        self.isGenerating || self.isAsking || self.isAddressingNotes
    }

    var loadingMessages: [String] {

        var messages: [String] = []
        if self.isLoadingHistory {
            messages.append("Loading Saved AI Reviews & Questions…")
        }
        if let modelLookupMessage = self.modelLookupMessage {
            messages.append(modelLookupMessage)
        }
        if let requestProgress = self.requestProgress {
            messages.append(requestProgress)
        }
        return messages

    }

    var recentQuestions: [AIConversationEntry] {
        (self.unsavedConversationEntries + self.conversations)
            .filter { if case .question = $0.output { return true }; return false }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var noteFixes: [AIConversationEntry] {
        (self.unsavedConversationEntries + self.conversations)
            .filter { if case .noteFix = $0.output { return true }; return false }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var historyItems: [AIReviewGeneration] {
        (self.unsavedGenerations + self.generations).sorted { $0.createdAt > $1.createdAt }
    }

    func isSaved(_ generation: AIReviewGeneration) -> Bool {
        self.generations.contains { $0.id == generation.id }
    }

    func update(details: PullRequestReviewDetails) {

        if self.details?.summary.baseSHA != details.summary.baseSHA || self.details?.summary.headSHA != details.summary.headSHA {
            cancelPendingRequests()
        }

        self.detailsRevision += 1
        self.details = details
        self.selectedPaths = self.selectedPaths.intersection(Set(details.files.map(\.filename)))

    }

    func clearCurrentDetails() {

        cancelPendingRequests()
        self.detailsRevision += 1
        self.details = nil

    }

    func updateAnnotations(_ annotations: [CodeAnnotation]) {

        let priorIDs = self.selectedAnnotationIDs
        self.availableAnnotations = annotations
        let availableIDs = Set(annotations.map(\.id))
        self.selectedAnnotationIDs = self.hasInitializedAnnotations ? priorIDs.intersection(availableIDs) : availableIDs
        self.hasInitializedAnnotations = true

    }

    func setAnnotationSelected(_ annotationID: UUID, selected: Bool) {

        if selected {
            self.selectedAnnotationIDs.insert(annotationID)
        } else {
            self.selectedAnnotationIDs.remove(annotationID)
        }

    }

    func prepareApply(_ entry: AIConversationEntry) {

        self.pendingApplyEntry = entry
        self.showsApplyConfirmation = true

    }

    func clearPendingApply() {

        self.pendingApplyEntry = nil
        self.showsApplyConfirmation = false

    }

    func hasGeneration(for visualization: AIVisualization) -> Bool {
        self.generations.contains { $0.visualizationType == visualization } || self.unsavedGenerations.contains { $0.visualizationType == visualization }
    }

    func activeGeneration(for visualization: AIVisualization) -> AIReviewGeneration? {

        if let selectedID = self.selectedGenerationIDs[visualization] {

            if let unsaved = self.unsavedGenerations.first(where: { $0.id == selectedID }) {
                return unsaved
            }

            if let selected = self.generations.first(where: { $0.id == selectedID }) {
                return selected
            }

        }

        return self.unsavedGenerations.first { $0.visualizationType == visualization }
            ?? self.generations.first { $0.visualizationType == visualization }

    }

    func selectGeneration(_ generation: AIReviewGeneration) {

        self.selectedGenerationIDs[generation.visualizationType] = generation.id
        self.requestedVisualization = generation.visualizationType

    }

    // Disclosure state is local to each saved generation, separate from immutable AI output.
    func expandedLearningSteps(for generation: AIReviewGeneration) -> Set<String> {

        if let expanded = self.expandedLearningStepIDs[generation.id] {
            return expanded
        }

        guard case .learningPath(let response) = generation.structuredOutput,
              let first = response.steps.first else { return [] }
        return [first.id]

    }

    func setExpandedLearningSteps(_ identifiers: Set<String>, for generation: AIReviewGeneration) {

        guard case .learningPath(let response) = generation.structuredOutput else { return }
        self.expandedLearningStepIDs[generation.id] = identifiers.intersection(Set(response.steps.map(\.id)))

    }

    func activate(_ visualization: AIVisualization) {
        self.selectedVisualization = visualization
    }

    func consumeRequestedVisualization() {
        self.requestedVisualization = nil
    }

    func revisionStatus(for generation: AIReviewGeneration) -> AIReviewRevisionStatus {

        guard let details = self.details else { return .unknown }
        return generation.isCurrent(baseSHA: details.summary.baseSHA, headSHA: details.summary.headSHA) ? .current : .outdated

    }

    func revisionStatus(for entry: AIConversationEntry) -> AIReviewRevisionStatus {

        guard let details = self.details else { return .unknown }
        return entry.baseSHA == details.summary.baseSHA && entry.headSHA == details.summary.headSHA ? .current : .outdated

    }

    func isCurrent(_ generation: AIReviewGeneration) -> Bool {
        if case .current = self.revisionStatus(for: generation) { return true }
        return false
    }

    func openComposer() {

        self.showsComposer = true
        self.errorMessage = nil
        refreshCommandStatus()
        let token = beginModelLookup()
        Task {
            if self.hasLoadedSettings {
                await self.refreshAvailableModels(expectedToken: token)
            } else {
                await self.loadSettings(expectedToken: token)
            }
            guard token == self.modelDiscoveryToken else { return }
            self.refreshModels()
        }

    }

    func openComposer(for visualization: AIVisualization) {

        self.selectedVisualization = visualization
        openComposer()

    }

    func selectProvider(_ provider: AIProviderKind) {

        self.selectedProvider = provider
        updateModelChoices()
        refreshCommandStatus()
        refreshModels()

    }

    func selectRoute(_ route: AIExecutionRoute) {

        self.selectedRoute = route
        updateModelChoices()
        refreshCommandStatus()
        refreshModels()

    }

    func refreshCommandStatus() {

        guard self.selectedRoute == .installedCLI else {
            self.commandStatus = nil
            return
        }

        let provider = self.selectedProvider
        Task {

            let status = await self.commandAvailability.availability(for: provider)
            if self.selectedProvider == provider && self.selectedRoute == .installedCLI {
                self.commandStatus = status
            }

        }

    }

    private func updateModelChoices() {

        self.modelChoices = self.settingsCache.models(for: self.selectedProvider, route: self.selectedRoute)
        if !self.modelChoices.contains(self.selectedModel) {
            self.selectedModel = self.modelChoices.first ?? ""
        }
        self.modelSource = nil
        self.modelNotice = nil
        self.modelError = nil

    }

    func refreshModels() {

        let token = beginModelLookup()
        let provider = self.selectedProvider
        let route = self.selectedRoute
        self.modelLookupMessage = "Checking \(provider.title) Access via \(route.title)…"
        self.modelDiscoveryTask = Task {
            await self.discoverModels(for: provider, route: route, token: token)
        }

    }

    private func beginModelLookup() -> Int {

        self.modelDiscoveryTask?.cancel()
        self.modelDiscoveryToken += 1
        self.isDiscoveringModels = true
        self.modelLookupMessage = "Loading AI Settings…"
        self.modelError = nil
        self.modelNotice = nil
        return self.modelDiscoveryToken

    }

    private func discoverModels(for provider: AIProviderKind, route: AIExecutionRoute, token: Int) async {

        defer {
            if token == self.modelDiscoveryToken {
                self.isDiscoveringModels = false
                self.modelLookupMessage = nil
            }
        }

        do {

            if route == .providerAPI {

                guard await self.credentialStore.hasAPIKey(for: provider) else {
                    throw AIReviewError.unavailable("Add a \(provider.title) API key in Settings → AI Review to fetch models.")
                }

            } else {

                let availability = await self.commandAvailability.availability(for: provider)
                guard availability.isAvailable else {
                    throw AIReviewError.unavailable(availability.problem ?? "Install and sign in to the \(provider.title) command line tool to fetch models.")
                }

            }

            guard token == self.modelDiscoveryToken else { return }
            self.modelLookupMessage = "Loading \(provider.title) Models via \(route.title)…"
            let catalog = try await self.modelCatalog.models(for: provider, route: route)
            try Task.checkCancellation()
            guard token == self.modelDiscoveryToken,
                  self.selectedProvider == provider,
                  self.selectedRoute == route else { return }
            guard !catalog.modelIDs.isEmpty else {
                throw AIReviewError.unavailable("No models were returned. Enter a model ID manually if you know one your account supports.")
            }

            self.modelChoices = catalog.modelIDs
            self.modelSource = catalog.sourceDescription
            if !catalog.modelIDs.contains(self.selectedModel) {

                let previousModel = self.selectedModel
                self.selectedModel = catalog.recommendedModelID.flatMap { catalog.modelIDs.contains($0) ? $0 : nil }
                    ?? catalog.modelIDs[0]
                self.modelNotice = previousModel.isEmpty
                    ? "Selected \(self.selectedModel) from the available models for this connection."
                    : "\(previousModel) is not listed for this connection. Selected \(self.selectedModel)."
                if let notice = catalog.notice, !notice.isEmpty {
                    self.modelNotice = "\(self.modelNotice ?? "") \(notice)"
                }

            } else {
                self.modelNotice = catalog.notice
            }

            do {

                self.modelLookupMessage = "Saving \(provider.title) Model List…"
                let saved = try await self.settingsStore.updateModels(
                    catalog.modelIDs,
                    for: provider,
                    route: route
                )
                guard token == self.modelDiscoveryToken,
                      self.selectedProvider == provider,
                      self.selectedRoute == route else { return }
                self.settingsCache = saved

            } catch {
                if token == self.modelDiscoveryToken {
                    self.modelError = "Models were fetched but could not be saved locally. \(error.localizedDescription)"
                }
            }

        } catch is CancellationError {
            return
        } catch {

            guard token == self.modelDiscoveryToken else { return }
            self.modelError = error.localizedDescription

        }

    }

    func loadHistory() async {

        guard !self.didLoadHistory, !self.isLoadingHistory else { return }
        self.isLoadingHistory = true
        defer { self.isLoadingHistory = false }
        let token = self.modelDiscoveryToken
        await loadSettings(expectedToken: token)
        self.didLoadHistory = await loadSavedResults()

    }

    func retryLoadingHistory() {
        Task { await self.loadHistory() }
    }

    func useDefaultModel() {

        let token = beginModelLookup()
        Task {
            await self.loadSettings(expectedToken: token)
            guard token == self.modelDiscoveryToken else { return }
            self.refreshModels()
        }

    }

    private func refreshAvailableModels(expectedToken: Int) async {

        do {
            let settings = try await self.settingsStore.loadSettings()
            guard expectedToken == self.modelDiscoveryToken else { return }
            self.settingsCache = settings
            self.modelChoices = settings.models(for: self.selectedProvider, route: self.selectedRoute)
        } catch {
            if expectedToken == self.modelDiscoveryToken {
                self.modelError = "AI model choices could not be refreshed. \(error.localizedDescription)"
            }
        }

    }

    private func loadSettings(expectedToken: Int) async {

        do {

            let settings = try await self.settingsStore.loadSettings()
            guard expectedToken == self.modelDiscoveryToken else { return }
            self.settingsCache = settings
            self.hasLoadedSettings = true
            self.selectedProvider = settings.defaultProvider
            self.selectedRoute = settings.defaultRoute
            self.modelChoices = settings.models(for: settings.defaultProvider, route: settings.defaultRoute)
            self.selectedModel = self.modelChoices.contains(settings.defaultModel)
                ? settings.defaultModel
                : (settings.defaultRoute == .providerAPI ? settings.defaultModel : "")
            refreshCommandStatus()

        } catch {
            if expectedToken == self.modelDiscoveryToken {
                self.errorMessage = "AI settings could not be loaded. \(error.localizedDescription)"
            }
        }

    }

    private func loadSavedResults() async -> Bool {

        var loadedAll = true

        do {

            let saved = try await self.historyStore.loadGenerations(
                repositoryIdentity: self.repositoryIdentity,
                pullRequestNumber: self.request.number
            )
            let merged = self.generations + saved
            self.generations = Array(Dictionary(merged.map { ($0.id, $0) }, uniquingKeysWith: { existing, _ in existing }).values)
                .sorted { $0.createdAt > $1.createdAt }
            if self.selectedGenerationIDs.isEmpty, let latest = self.generations.first {
                self.selectedGenerationIDs[latest.visualizationType] = latest.id
                self.requestedVisualization = latest.visualizationType
            }

        } catch {
            loadedAll = false
            self.persistenceMessage = "Saved AI reviews could not be loaded. \(error.localizedDescription)"
        }

        do {

            let saved = try await self.historyStore.loadConversation(
                repositoryIdentity: self.repositoryIdentity,
                pullRequestNumber: self.request.number
            )
            let merged = self.conversations + saved
            self.conversations = Array(Dictionary(merged.map { ($0.id, $0) }, uniquingKeysWith: { existing, _ in existing }).values)
                .sorted { $0.createdAt > $1.createdAt }
            self.proposedFixEntry = self.conversations.first { if case .noteFix = $0.output { return true }; return false }

        } catch {
            loadedAll = false
            self.persistenceMessage = "Saved AI activity could not be loaded. \(error.localizedDescription)"
        }

        if loadedAll && self.unsavedGenerations.isEmpty && self.unsavedConversationEntries.isEmpty {
            self.persistenceMessage = nil
        }
        return loadedAll

    }

    func regenerate(visualization: AIVisualization) {

        self.selectedVisualization = visualization
        if let generation = activeGeneration(for: visualization) {

            self.userPrompt = generation.userPrompt
            self.selectedProvider = generation.provider
            self.selectedModel = generation.model
            self.selectedRoute = generation.route

        }
        openComposer(for: visualization)

    }

    func generate() {

        guard !self.isBusy, !self.isDiscoveringModels else { return }
        self.isGenerating = true
        self.requestProgress = "Checking \(self.selectedProvider.title) Connection…"
        self.generationTask = Task { await self.performGeneration() }

    }

    func cancelGeneration() {
        self.generationTask?.cancel()
    }

    private func performGeneration() async {

        defer {
            self.isGenerating = false
            self.requestProgress = nil
        }
        guard let details = self.details else {
            self.errorMessage = "Load the pull request before generating an AI review. Saved reviews are still available."
            return
        }

        self.errorMessage = nil
        if self.unsavedGenerations.isEmpty && self.unsavedConversationEntries.isEmpty {
            self.persistenceMessage = nil
        }
        let revision = self.detailsRevision

        let visualization = self.selectedVisualization
        let provider = self.selectedProvider
        let model = self.selectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let route = self.selectedRoute
        let prompt = self.userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        do {

            try await verifyProvider(provider, model: model, route: route)
            let details = try await detailsWithCurrentConversation(details, revision: revision)
            self.requestProgress = visualization == .riskMap ? "Loading The Complete Pull Request Diff…" : "Preparing Pull Request Context…"
            let context: AIReviewContext
            if visualization == .riskMap {

                guard details.hasAllFiles else {
                    throw AIReviewError.unavailable("GitHub did not return every changed file. Refresh before generating a Risk Map.")
                }
                let files = try await self.completeReviewFiles(details)
                try Task.checkCancellation()
                try verifyRequestRevision(revision)
                context = AIContextBuilder.makeCompleteRiskContext(
                    details: details,
                    repositoryIdentity: self.repositoryIdentity,
                    files: files
                )

            } else {
                context = makeContext(details: details)
            }
            self.requestProgress = "Generating \(visualization.title) With \(provider.title)…"
            let output = try await self.reviewService.generate(
                visualization: visualization,
                context: context,
                provider: provider,
                model: model,
                route: route,
                userPrompt: prompt,
                progress: { [weak self] message in
                    self?.requestProgress = message
                }
            )
            try Task.checkCancellation()
            try verifyRequestRevision(revision)
            guard output.visualizationType == visualization else {
                throw AIReviewError.invalidResponse("The provider returned a different review type.")
            }

            let generation = makeGeneration(
                output: output,
                visualization: visualization,
                provider: provider,
                model: model,
                route: route,
                prompt: prompt,
                context: context,
                details: details
            )
            if visualization == .riskMap {
                self.selectedRiskID = nil
                self.selectedRiskFilePath = nil
                self.riskFileFilter = nil
            }
            self.requestProgress = "Saving \(visualization.title) Locally…"
            await saveGeneration(generation)
            self.showsComposer = false
            self.requestedVisualization = visualization

        } catch is CancellationError {
            return
        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    private func detailsWithCurrentConversation(
        _ details: PullRequestReviewDetails,
        revision: Int
    ) async throws -> PullRequestReviewDetails {

        self.requestProgress = "Loading PR Comments & Reviews…"
        let conversation = try await self.loadReviewConversation()
        try Task.checkCancellation()
        try verifyRequestRevision(revision)
        return details.replacingConversation(conversation)

    }

    private func makeContext(details: PullRequestReviewDetails, annotations: [CodeAnnotation] = []) -> AIReviewContext {

        let selectedPaths: [String]
        if annotations.isEmpty {
            selectedPaths = Array(self.selectedPaths)
        } else {

            let notePaths = Set(annotations.map(\.filePath))
            let renamedPaths = details.files.filter { file in
                file.previousFilename.map(notePaths.contains) ?? false
            }.map(\.filename)
            selectedPaths = Array(notePaths.union(renamedPaths))

        }

        return AIContextBuilder.makeContext(
            details: details,
            repositoryIdentity: self.repositoryIdentity,
            selectedPaths: selectedPaths,
            annotations: annotations
        )
    }

    private func makeGeneration(
        output: AIReviewOutput,
        visualization: AIVisualization,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute,
        prompt: String,
        context: AIReviewContext,
        details: PullRequestReviewDetails
    ) -> AIReviewGeneration {

        let analyzedFiles = visualization == .riskMap ? [] : details.files.map { file in
            AIFileSnapshot(
                filename: file.filename,
                previousFilename: file.previousFilename,
                status: file.status,
                additions: file.additions,
                deletions: file.deletions,
                patch: file.patch
            )
        }

        return AIReviewGeneration(
            id: UUID(),
            repositoryIdentity: self.repositoryIdentity,
            pullRequestNumber: self.request.number,
            visualizationType: visualization,
            provider: provider,
            model: model,
            route: route,
            createdAt: Date(),
            baseSHA: details.summary.baseSHA,
            headSHA: details.summary.headSHA,
            userPrompt: prompt,
            structuredOutput: output,
            context: context,
            analyzedFiles: analyzedFiles
        )

    }

    private func saveGeneration(_ generation: AIReviewGeneration) async {

        do {

            try await self.historyStore.appendGeneration(generation)
            if !self.generations.contains(where: { $0.id == generation.id }) {
                self.generations.insert(generation, at: 0)
            }
            self.unsavedGenerations.removeAll { $0.id == generation.id }
            if self.unsavedGenerations.isEmpty && self.unsavedConversationEntries.isEmpty {
                self.persistenceMessage = nil
            }

        } catch {
            if !self.unsavedGenerations.contains(where: { $0.id == generation.id }) {
                self.unsavedGenerations.insert(generation, at: 0)
            }
            self.persistenceMessage = "This result is visible now but was not saved. \(error.localizedDescription)"
        }

        self.selectedGenerationIDs[generation.visualizationType] = generation.id

    }

    func retrySaveGeneration() {

        let pending = self.unsavedGenerations
        Task {
            for generation in pending { await self.saveGeneration(generation) }
        }

    }

    func askQuestion() {

        guard !self.isBusy, !self.isDiscoveringModels else { return }
        self.isAsking = true
        self.requestProgress = "Checking \(self.selectedProvider.title) Connection…"
        self.questionTask = Task { await self.performQuestion() }

    }

    func cancelQuestion() {
        self.questionTask?.cancel()
    }

    private func performQuestion() async {

        defer {
            self.isAsking = false
            self.requestProgress = nil
        }
        guard let details = self.details else {
            self.errorMessage = "Load the pull request before asking a question."
            return
        }

        let question = self.questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        self.errorMessage = nil
        let revision = self.detailsRevision

        do {

            let provider = self.selectedProvider
            let model = self.selectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
            let route = self.selectedRoute
            try await verifyProvider(provider, model: model, route: route)
            let details = try await detailsWithCurrentConversation(details, revision: revision)
            self.requestProgress = "Preparing Pull Request Context…"
            let context = makeContext(details: details)
            self.requestProgress = "Waiting For \(provider.title) To Answer…"
            let response = try await self.reviewService.ask(
                question: question,
                context: context,
                provider: provider,
                model: model,
                route: route
            )
            try Task.checkCancellation()
            try verifyRequestRevision(revision)
            let entry = makeConversationEntry(
                prompt: question,
                annotations: [],
                output: .question(response),
                context: context,
                details: details,
                provider: provider,
                model: model,
                route: route
            )
            self.requestProgress = "Saving AI Answer Locally…"
            await saveConversation(entry)
            self.questionText = ""

        } catch is CancellationError {
            return
        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    func addressSelectedNotes() {

        guard !self.isBusy, !self.isDiscoveringModels else { return }
        self.isAddressingNotes = true
        self.requestProgress = "Checking \(self.selectedProvider.title) Connection…"
        self.notesTask = Task { await self.performNoteFix() }

    }

    func cancelNoteFix() {
        self.notesTask?.cancel()
    }

    private func performNoteFix() async {

        defer {
            self.isAddressingNotes = false
            self.requestProgress = nil
        }
        guard let details = self.details else {
            self.errorMessage = "Load the pull request before addressing review notes."
            return
        }

        let annotations = self.selectedAnnotations
        guard !annotations.isEmpty else {
            self.errorMessage = "Select at least one review note."
            return
        }

        self.errorMessage = nil
        let revision = self.detailsRevision

        do {

            let provider = self.selectedProvider
            let model = self.selectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
            let route = self.selectedRoute
            try await verifyProvider(provider, model: model, route: route)
            let details = try await detailsWithCurrentConversation(details, revision: revision)
            self.requestProgress = "Preparing Selected Review Notes…"
            let context = makeContext(details: details, annotations: annotations)
            self.requestProgress = "Waiting For \(provider.title) To Propose A Fix…"
            let response = try await self.reviewService.addressNotes(
                context: context,
                provider: provider,
                model: model,
                route: route
            )
            try Task.checkCancellation()
            try verifyRequestRevision(revision)
            let entry = makeConversationEntry(
                prompt: "Address \(annotations.count) Review \(annotations.count == 1 ? "Note" : "Notes")",
                annotations: annotations,
                output: .noteFix(response),
                context: context,
                details: details,
                provider: provider,
                model: model,
                route: route
            )
            self.requestProgress = "Saving Proposed Fix Locally…"
            await saveConversation(entry)
            self.proposedFixEntry = entry
            self.showsComposer = false

        } catch is CancellationError {
            return
        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    private func makeConversationEntry(
        prompt: String,
        annotations: [CodeAnnotation],
        output: AIConversationOutput,
        context: AIReviewContext,
        details: PullRequestReviewDetails,
        provider: AIProviderKind,
        model: String,
        route: AIExecutionRoute
    ) -> AIConversationEntry {

        let analyzedNotes = annotations.map(AIAnnotationContext.init(annotation:))
        let analyzedFiles: [AIFileSnapshot]
        if case .noteFix = output {
            analyzedFiles = details.files.map { file in
                AIFileSnapshot(
                    filename: file.filename,
                    previousFilename: file.previousFilename,
                    status: file.status,
                    additions: file.additions,
                    deletions: file.deletions,
                    patch: file.patch
                )
            }
        } else {
            analyzedFiles = []
        }

        return AIConversationEntry(
            id: UUID(),
            repositoryIdentity: self.repositoryIdentity,
            pullRequestNumber: self.request.number,
            createdAt: Date(),
            baseSHA: details.summary.baseSHA,
            headSHA: details.summary.headSHA,
            provider: provider,
            model: model,
            route: route,
            userPrompt: prompt,
            annotationIDs: annotations.map(\.id),
            analyzedNotes: analyzedNotes,
            analyzedFiles: analyzedFiles,
            context: context,
            output: output
        )

    }

    private func saveConversation(_ entry: AIConversationEntry) async {

        do {

            try await self.historyStore.appendConversation(entry)
            if !self.conversations.contains(where: { $0.id == entry.id }) {
                self.conversations.insert(entry, at: 0)
            }
            self.unsavedConversationEntries.removeAll { $0.id == entry.id }
            if self.unsavedGenerations.isEmpty && self.unsavedConversationEntries.isEmpty {
                self.persistenceMessage = nil
            }

        } catch {
            if !self.unsavedConversationEntries.contains(where: { $0.id == entry.id }) {
                self.unsavedConversationEntries.insert(entry, at: 0)
            }
            self.persistenceMessage = "This AI response is visible now but was not saved. \(error.localizedDescription)"
        }

    }

    func retrySaveConversation() {

        let pending = self.unsavedConversationEntries
        Task {
            for entry in pending { await self.saveConversation(entry) }
        }

    }

    func selectNoteFix(_ entry: AIConversationEntry) {

        guard case .noteFix = entry.output else { return }
        self.proposedFixEntry = entry
        self.showsComposer = false

    }

    private func verifyProvider(_ provider: AIProviderKind, model: String, route: AIExecutionRoute) async throws {

        guard !model.isEmpty else {
            throw AIReviewError.invalidResponse("Choose a model before sending a request.")
        }

        switch route {

        case .providerAPI:
            guard await self.credentialStore.hasAPIKey(for: provider) else {
                throw AIReviewError.unavailable("Add a \(provider.title) API key in Settings → AI before sending a request.")
            }

        case .installedCLI:
            let status = await self.commandAvailability.availability(for: provider)
            self.commandStatus = status
            guard status.isAvailable else {
                throw AIReviewError.unavailable(status.problem ?? "Install and sign in to the \(provider.title) command line tool before using it.")
            }

        }

    }

    private func verifyRequestRevision(_ revision: Int) throws {

        guard revision == self.detailsRevision else {
            throw AIReviewError.unavailable("The pull request context changed while AI was running. Refresh the review and try again.")
        }

    }

    private func cancelPendingRequests() {

        self.generationTask?.cancel()
        self.questionTask?.cancel()
        self.notesTask?.cancel()

    }

}
