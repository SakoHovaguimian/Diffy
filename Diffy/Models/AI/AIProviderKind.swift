import Foundation

enum AIProviderKind: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case openAI
    case anthropic
    case gemini

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"

        }

    }
}
