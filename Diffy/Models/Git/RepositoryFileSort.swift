import Foundation

enum RepositoryFileSort: String, CaseIterable, Identifiable {
    case name = "Name"
    case lastUpdated = "Last updated"

    var id: String { self.rawValue }
}
