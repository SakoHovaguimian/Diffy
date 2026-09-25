import Foundation

struct LocalProjectRecord: Codable, Identifiable {
    let id: String
    let directoryPath: String
    let bucketID: String
    var name: String
    var symbol: String

    var project: RepositoryProject {

        RepositoryProject(
            id: self.id,
            name: self.name,
            subtitle: self.directoryPath,
            bucketID: self.bucketID,
            symbol: self.symbol,
            branch: "",
            language: "",
            updatedLabel: "",
            files: [],
            commits: [],
            directoryPath: self.directoryPath
        )

    }
}
