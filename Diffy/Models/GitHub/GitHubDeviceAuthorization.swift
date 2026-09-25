import Foundation

/// A pending Device Flow authorization. The user enters `userCode` at
/// `verificationURL`. `deviceCode` is opaque and must never be displayed or logged.
struct GitHubDeviceAuthorization: Hashable, Identifiable, Sendable {
    let id: UUID
    let host: String
    let userCode: String
    let verificationURL: URL
    let deviceCode: String
    let expiresAt: Date
    let pollingInterval: TimeInterval
    var reconnectingAccountID: String?
}
