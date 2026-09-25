import Foundation

struct RepositoryTag: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let commitID: String

    var id: String {
        self.name
    }
}
