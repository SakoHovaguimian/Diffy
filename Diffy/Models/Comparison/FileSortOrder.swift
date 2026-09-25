import Foundation

enum FileSortOrder: String, CaseIterable, Codable, Identifiable {

    case path = "File structure"
    case name = "Name"
    case updated = "Last edited on disk"
    case changeSize = "Lines changed"
    case status = "Change type"
    case size = "File size"
    case fileType = "File type"

    var id: String { self.rawValue }

}
