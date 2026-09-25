import Foundation

struct ProjectEditorDraft: Identifiable {

    let id = UUID()
    let projectID: String?
    let directoryURL: URL?
    let bucketID: String
    let repositoryName: String
    var displayName: String
    var symbol: String

    init(
        directoryURL: URL,
        bucketID: String
    ) {

        self.projectID = nil
        self.directoryURL = directoryURL
        self.bucketID = bucketID
        self.repositoryName = directoryURL.lastPathComponent
        self.displayName = directoryURL.lastPathComponent
        self.symbol = "folder.fill"

    }

    init(
        project: RepositoryProject,
        bucketID: String
    ) {

        self.projectID = project.id
        self.directoryURL = project.checkout.map { URL(fileURLWithPath: $0.lastKnownPath, isDirectory: true) }
        self.bucketID = bucketID
        self.repositoryName = project.gitHubLink?.fullName ?? project.repositoryName
        self.displayName = project.displayName
        self.symbol = project.symbol

    }

    var isEditing: Bool {
        self.projectID != nil
    }

}
