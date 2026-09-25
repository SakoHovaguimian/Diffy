import Foundation

enum RepositoryFileSort: String, CaseIterable, Identifiable {
    case name = "Name"
    case lastUpdated = "Last Updated"

    var id: String { self.rawValue }
}
