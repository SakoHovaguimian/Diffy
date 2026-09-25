import Foundation

/// Public GitHub App settings read from the target's Info.plist. A client ID is not a
/// secret; the app never embeds a client secret or private key.
struct GitHubAppConfiguration: Hashable, Sendable {
    let clientID: String?
    let host: String
    let appSlug: String?

    static let unconfigured = GitHubAppConfiguration(clientID: nil, host: "github.com", appSlug: nil)

    var isConfigured: Bool {
        !(self.clientID ?? "").isEmpty
    }

    var webBaseURL: URL? {
        URL(string: "https://\(self.host)")
    }

    var apiBaseURL: URL? {

        if self.host == "github.com" {
            return URL(string: "https://api.github.com")
        }

        return URL(string: "https://\(self.host)/api/v3")

    }

    var installationURL: URL? {

        guard let appSlug = self.appSlug, !appSlug.isEmpty else {
            return nil
        }

        return URL(string: "https://\(self.host)/apps/\(appSlug)/installations/new")

    }
}
