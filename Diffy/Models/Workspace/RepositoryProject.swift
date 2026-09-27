import Foundation

/// A project in Diffy. Presentation, Bucket membership, the optional local checkout, and
/// the optional GitHub link are independent. Remotes and status come from Git snapshots.
struct RepositoryProject: Codable, Identifiable, Hashable, Sendable {

    let id: String
    var name: String
    var displayName: String
    var subtitle: String
    var bucketID: String
    var symbol: String
    var customIcon: WorkspaceCustomIcon?
    var accentHex: String?
    var checkout: LocalCheckoutReference?
    var gitHubLink: GitHubRepositoryLink?
    var gitHubAccountID: String?
    let addedAt: Date

    init(
        id: String,
        name: String,
        displayName: String? = nil,
        subtitle: String,
        bucketID: String,
        symbol: String,
        customIcon: WorkspaceCustomIcon? = nil,
        accentHex: String? = nil,
        checkout: LocalCheckoutReference?,
        gitHubLink: GitHubRepositoryLink?,
        gitHubAccountID: String?,
        addedAt: Date
    ) {

        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.subtitle = subtitle
        self.bucketID = bucketID
        self.symbol = symbol
        self.customIcon = customIcon
        self.accentHex = accentHex
        self.checkout = checkout
        self.gitHubLink = gitHubLink
        self.gitHubAccountID = gitHubAccountID
        self.addedAt = addedAt

    }

    var repositoryName: String {
        self.gitHubLink?.coordinate.name ?? self.name
    }

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
