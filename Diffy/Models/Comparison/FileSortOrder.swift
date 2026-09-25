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

    /// Presentation copy is separate from raw values stored in preferences and review data.
    var displayName: String {

        switch self {

        case .path: "File Structure"
        case .name: "Name"
        case .updated: "Last Edited On Disk"
        case .changeSize: "Lines Changed"
        case .status: "Change Type"
        case .size: "File Size"
        case .fileType: "File Type"

        }

    }

}
