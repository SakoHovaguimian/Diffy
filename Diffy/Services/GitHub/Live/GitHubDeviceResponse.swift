import Foundation

struct GitHubDeviceResponse: Decodable, Sendable {
    let deviceCode: String
    let userCode: String
    let verificationUri: URL
    let expiresIn: TimeInterval
    let interval: TimeInterval
}
