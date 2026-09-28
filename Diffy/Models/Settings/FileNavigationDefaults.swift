import Foundation

struct FileNavigationDefaults: Codable, Equatable {

    static let storageKey = "navigation.defaults.v1"

    /// Nil preserves each sidebar's existing initial layout.
    var layout: FileListLayout? = nil
    var sort: FileSortOrder = .path

}
