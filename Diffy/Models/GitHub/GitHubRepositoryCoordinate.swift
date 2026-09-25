import Foundation

/// A host/owner/name triple parsed from a remote URL. Parsing never retains user-info.
struct GitHubRepositoryCoordinate: Codable, Hashable, Sendable {
    let host: String
    let owner: String
    let name: String

    var fullName: String {
        "\(self.owner)/\(self.name)"
    }

    init(
        host: String,
        owner: String,
        name: String
    ) {

        self.host = host.lowercased()
        self.owner = owner
        self.name = name

    }

    /// Accepts `https://host/owner/name(.git)`, `ssh://git@host/owner/name(.git)`,
    /// and scp-style `git@host:owner/name(.git)` remotes on GitHub hosts.
    init?(remoteURL: String) {

        guard let parts = Self.hostAndPath(from: remoteURL) else {
            return nil
        }

        let pathComponents = parts.path.split(separator: "/").map(String.init)

        guard Self.isGitHubHost(parts.host),
              pathComponents.count == 2,
              let owner = pathComponents.first,
              let name = pathComponents.last.map(Self.trimmingGitSuffix),
              !owner.isEmpty,
              !name.isEmpty else {
            return nil
        }

        self.init(host: parts.host, owner: owner, name: name)

    }

    // MARK: - Parsing

    private static func hostAndPath(from remoteURL: String) -> (host: String, path: String)? {

        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed), let host = url.host, url.scheme != nil {
            return (host, url.path)
        }

        return scpStyleHostAndPath(trimmed)

    }

    private static func scpStyleHostAndPath(_ remoteURL: String) -> (host: String, path: String)? {

        guard let colon = remoteURL.firstIndex(of: ":") else {
            return nil
        }

        let authority = remoteURL[..<colon]
        let path = remoteURL[remoteURL.index(after: colon)...]
        let host = authority.split(separator: "@").last.map(String.init) ?? String(authority)

        return host.isEmpty ? nil : (host, String(path))

    }

    private static func isGitHubHost(_ host: String) -> Bool {

        let lowercased = host.lowercased()
        return lowercased == "github.com" || lowercased.hasSuffix(".github.com") || lowercased.hasPrefix("github.")

    }

    private static func trimmingGitSuffix(_ name: String) -> String {
        name.hasSuffix(".git") ? String(name.dropLast(4)) : name
    }
}
