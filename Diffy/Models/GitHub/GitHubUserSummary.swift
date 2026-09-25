import Foundation

struct GitHubUserSummary: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let login: String
    var name: String?
    let avatarURL: URL?

    private enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case avatarURL = "avatarUrl"
    }

    var initials: String {
        String(self.login.prefix(2)).uppercased()
    }
}
