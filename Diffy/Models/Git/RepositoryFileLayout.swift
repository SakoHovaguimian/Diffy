import Foundation

enum RepositoryFileLayout: String, CaseIterable, Identifiable {
    case tree = "Tree"
    case flat = "Files"

    var id: String { self.rawValue }
}
