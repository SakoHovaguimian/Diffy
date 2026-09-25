import Foundation

struct GitHubUserSummary: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let login: String
    var name: String?

    var initials: String {
        String(self.login.prefix(2)).uppercased()
    }
}
