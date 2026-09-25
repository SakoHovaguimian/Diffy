import Foundation

enum GitHubError: Error, Hashable, Sendable {
    case notConfigured
    case accountNotFound
    case reauthorizationRequired(accountID: String)
    case forbidden(String)
    case notFound
    case rateLimited(resetsAt: Date?)
    case offline
    case server(status: Int)
    case invalidResponse(String)
    case authorizationExpired
    case authorizationDenied
    case authorizationPending
    case credentialStorage(String)
    case cancelled
}

extension GitHubError: LocalizedError {

    var errorDescription: String? {

        switch self {

        case .notConfigured: "GitHub isn't configured for this build."
        case .accountNotFound: "That GitHub account is no longer connected."
        case .reauthorizationRequired: "This GitHub account needs to be reconnected."
        case let .forbidden(message): message.isEmpty ? "GitHub denied access to this resource." : message
        case .notFound: "GitHub couldn't find that repository, or this account can't see it."
        case let .rateLimited(resetsAt): "GitHub's rate limit was reached\(resetsAt.map { ". It resets \($0.formatted(date: .omitted, time: .shortened))" } ?? "")."
        case .offline: "You're offline. Showing the last saved GitHub data."
        case let .server(status): "GitHub returned an unexpected response (\(status))."
        case let .invalidResponse(detail): "GitHub's response couldn't be read. \(detail)"
        case .authorizationExpired: "The sign-in code expired before it was entered."
        case .authorizationDenied: "The GitHub authorization was declined."
        case .authorizationPending: "Waiting for you to approve Diffy on GitHub."
        case let .credentialStorage(detail): "The Keychain couldn't store the GitHub credential. \(detail)"
        case .cancelled: "The GitHub request was cancelled."

        }

    }

    var recoverySuggestion: String? {

        switch self {

        case .notConfigured: "See docs/GITHUB_SETUP.md to add a GitHub App client ID. Local Git features work without it."
        case .reauthorizationRequired: "Open Settings → Accounts and choose Reconnect."
        case .notFound, .forbidden: "Install the GitHub App on this repository, or choose another account."
        case .authorizationExpired: "Start the connection again to get a new code."
        default: nil

        }

    }
}
