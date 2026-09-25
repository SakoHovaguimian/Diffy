import Foundation

/// A project in Diffy. Presentation, Bucket membership, the optional local checkout, and
/// the optional GitHub link are independent. Remotes and status come from Git snapshots.
struct RepositoryProject: Codable, Identifiable, Hashable, Sendable {

    let id: String
    var name: String
    var subtitle: String
    var bucketID: String
    var symbol: String
    var checkout: LocalCheckoutReference?
    var gitHubLink: GitHubRepositoryLink?
    var gitHubAccountID: String?
    let addedAt: Date

    var repositoryReference: GitRepositoryReference? {
        self.checkout.map { GitRepositoryReference(projectID: self.id, checkout: $0) }
    }

    var displaySubtitle: String {
        self.subtitle.isEmpty ? (self.checkout?.displayPath ?? "") : self.subtitle
    }

    var isGitHubLinked: Bool {
        self.gitHubLink != nil
    }

}
