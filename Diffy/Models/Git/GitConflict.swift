import Foundation

struct GitConflict: Codable, Hashable, Identifiable, Sendable {
    let path: String
    let kind: GitConflictKind

    var id: String {
        self.path
    }
}
