import Foundation

/// Conditional-request validators saved with a cached GitHub response.
struct GitHubResourceValidators: Codable, Hashable, Sendable {
    var entityTag: String?
    var lastModified: String?

    static let none = GitHubResourceValidators()

    var isEmpty: Bool {
        self.entityTag == nil && self.lastModified == nil
    }
}
