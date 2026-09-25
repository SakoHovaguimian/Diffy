import Foundation

enum FileListLayout: String, CaseIterable, Codable, Identifiable {

    case tree = "Folder tree"
    case flat = "Flat list"
    case status = "Change status"
    case fileType = "File type"

    var id: String { self.rawValue }

    /// Presentation copy is separate from raw values stored in preferences and review data.
    var displayName: String {

        switch self {

        case .tree: "Folder Tree"
        case .flat: "Flat List"
        case .status: "Change Status"
        case .fileType: "File Type"

        }

    }

}
