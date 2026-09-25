import Foundation

struct GitHubTokenResponse: Decodable, Sendable {
    let accessToken: String?
    let expiresIn: TimeInterval?
    let error: String?
    let refreshToken: String?
    let refreshTokenExpiresIn: TimeInterval?
}
