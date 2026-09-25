import Foundation

/// Non-secret metadata for one GitHub connection. Tokens live only in the Keychain,
/// keyed by `id`. Two connections to the same host are independent accounts.
/// This is authentication identity only; Git author identity stays in Git config.
struct GitHubAccount: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let host: String
    let userID: Int
    var login: String
    var displayName: String?
    let connectedAt: Date
    var status: GitHubAccountStatus

    var handle: String {
        "@\(self.login)"
    }

    var initials: String {

        let source = self.displayName?.isEmpty == false ? self.displayName ?? self.login : self.login
        let words = source.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "_" })
        let letters = words.prefix(2).compactMap(\.first)

        return String(letters).uppercased()

    }
}
