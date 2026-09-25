import Foundation

enum FileListLayout: String, CaseIterable, Codable, Identifiable {
    case tree = "Folder tree"
    case flat = "Flat list"
    case status = "Change status"
    case fileType = "File type"

    var id: String { self.rawValue }
}
