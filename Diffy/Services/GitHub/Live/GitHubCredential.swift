import Foundation

struct GitHubCredential: Codable, Sendable {
    let accessToken: String
    let expiresAt: Date?
    let isPersonalToken: Bool
    var refreshToken: String?
    var refreshTokenExpiresAt: Date?
}
