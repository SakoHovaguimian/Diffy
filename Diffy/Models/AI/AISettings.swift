import Foundation

struct AISettings: Codable, Hashable, Sendable {
    var defaultProvider: AIProviderKind
    var defaultModel: String
    var defaultRoute: AIExecutionRoute
    var availableModels: [AIProviderKind: [String]]
    /// Missing in settings saved before CLI discovery was introduced.
    var availableCLIModels: [AIProviderKind: [String]]? = nil

    static let initial = AISettings(
        defaultProvider: .openAI,
        defaultModel: "gpt-5.4",
        defaultRoute: .providerAPI,
        availableModels: [
            .openAI: ["gpt-5.4", "gpt-5.4-mini"],
            .anthropic: ["claude-sonnet-5", "claude-haiku-4-5-20251001"],
            .gemini: ["gemini-2.5-pro", "gemini-2.5-flash"]
        ]
    )

    func models(for provider: AIProviderKind) -> [String] {
        self.availableModels[provider] ?? []
    }

    func models(for provider: AIProviderKind, route: AIExecutionRoute) -> [String] {

        switch route {

        case .providerAPI: self.availableModels[provider] ?? []
        case .installedCLI: self.availableCLIModels?[provider] ?? []

        }

    }

    mutating func setModels(_ modelIDs: [String], for provider: AIProviderKind, route: AIExecutionRoute) {

        let uniqueIDs = Array(NSOrderedSet(array: modelIDs)).compactMap { $0 as? String }

        switch route {

        case .providerAPI:
            self.availableModels[provider] = uniqueIDs

        case .installedCLI:
            if self.availableCLIModels == nil { self.availableCLIModels = [:] }
            self.availableCLIModels?[provider] = uniqueIDs

        }

    }

    mutating func applyChanges(from edited: AISettings, comparedWith baseline: AISettings) {

        if edited.defaultProvider != baseline.defaultProvider {
            self.defaultProvider = edited.defaultProvider
        }

        if edited.defaultModel != baseline.defaultModel {
            self.defaultModel = edited.defaultModel
        }

        if edited.defaultRoute != baseline.defaultRoute {
            self.defaultRoute = edited.defaultRoute
        }

        for provider in AIProviderKind.allCases {
            for route in AIExecutionRoute.allCases {

                let previous = baseline.models(for: provider, route: route)
                let changed = edited.models(for: provider, route: route)
                if changed != previous {
                    self.setModels(changed, for: provider, route: route)
                }

            }
        }

    }
}
