import Foundation

enum AIReviewError: LocalizedError, Sendable {
    case missingCredential(AIProviderKind)
    case unavailable(String)
    case requestFailed
    case incompleteResponse
    case invalidResponse(String)
    case storageUnavailable

    var errorDescription: String? {

        switch self {

        case .missingCredential(let provider): "Add an API key for \(provider.title) in Settings."
        case .unavailable(let message): message
        case .requestFailed: "The AI provider could not complete this request. Check your connection and model selection."
        case .incompleteResponse: "The AI response was incomplete. Try a smaller selection or regenerate."
        case .invalidResponse(let detail): "The AI response could not be used: \(detail)"
        case .storageUnavailable: "Diffy could not safely read or save this AI history."

        }

    }
}
