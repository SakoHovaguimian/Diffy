import Foundation

enum RepositoryFileSort: String, CaseIterable, Codable, Identifiable {
    case name = "Name"
    case lastUpdated = "Last Updated"

    var id: String { self.rawValue }
}
