import Foundation

/// Cloning always uses the Mac's existing Git authentication. Diffy never places a
/// GitHub API token in a remote URL.
enum GitCloneTransport: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case https
    case ssh

    var id: String {
        self.rawValue
    }

    var title: String {

        switch self {

        case .https: "HTTPS"
        case .ssh: "SSH"

        }

    }

    func remoteURL(for repository: GitHubRepositorySummary) -> String {
        self == .https ? repository.httpsCloneURL : repository.sshCloneURL
    }
}
