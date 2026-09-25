import Foundation

struct NewProjectDraft: Identifiable {

    let id = UUID()
    let directoryPath: String
    let bucketID: String
    var name: String
    var symbol: String = "folder.fill"

}
