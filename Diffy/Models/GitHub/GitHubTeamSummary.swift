import Foundation

struct GitHubTeamSummary: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let slug: String
    let name: String
}
