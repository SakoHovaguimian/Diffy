import Foundation

struct FileNavigationPreferences: Codable {
    var sort: FileSortOrder = .path
    var layout: FileListLayout = .tree
    var ascending: Bool = true
    var filter: FileChangeStatus?
}
