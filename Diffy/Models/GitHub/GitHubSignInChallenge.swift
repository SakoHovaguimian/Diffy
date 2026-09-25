import Foundation

struct GitHubSignInChallenge: Sendable {
    let userCode: String
    let verificationURL: URL
    let expiresAt: Date
    let providerName: String
}
