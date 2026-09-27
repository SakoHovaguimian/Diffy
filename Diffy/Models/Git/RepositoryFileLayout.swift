import Foundation

enum RepositoryFileLayout: String, CaseIterable, Codable, Identifiable {
    case tree = "Tree"
    case flat = "Files"

    var id: String { self.rawValue }
}
