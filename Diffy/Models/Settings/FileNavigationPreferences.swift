import Foundation

struct FileNavigationPreferences: Codable {

    var ascending: Bool = true
    var filter: FileChangeStatus?

}
