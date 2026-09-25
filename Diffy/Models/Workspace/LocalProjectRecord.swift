import Foundation

/// The Milestone 0 folder reference saved under `projects.local.v1`. It stored a plain
/// path without a security-scoped bookmark and is read only to migrate existing records.
struct LocalProjectRecord: Codable, Identifiable {

    let id: String
    let directoryPath: String
    let bucketID: String
    var name: String
    var symbol: String

    func migratedProject(checkout: LocalCheckoutReference, migratedAt: Date) -> RepositoryProject {

        RepositoryProject(
            id: self.id,
            name: self.name,
            subtitle: "",
            bucketID: self.bucketID,
            symbol: self.symbol,
            checkout: checkout,
            gitHubLink: nil,
            gitHubAccountID: nil,
            addedAt: migratedAt
        )

    }

}
