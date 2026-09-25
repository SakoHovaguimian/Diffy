import Foundation

/// A GitHub App installation visible to a connected account.
struct GitHubInstallation: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let accountLogin: String
    let accountType: String
}
