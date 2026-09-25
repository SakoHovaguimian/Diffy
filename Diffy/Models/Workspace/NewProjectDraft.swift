import Foundation

struct NewProjectDraft: Identifiable {

    let id = UUID()
    let directoryURL: URL
    let bucketID: String
    var name: String
    var symbol: String = "folder.fill"

    var directoryPath: String {
        self.directoryURL.path
    }

}
