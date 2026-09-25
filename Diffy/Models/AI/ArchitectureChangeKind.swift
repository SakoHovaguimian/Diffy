import Foundation

enum ArchitectureChangeKind: String, Codable, Hashable, Sendable {
    case changed
    case existingAffected
    case unchangedDependency
    case newDependency
}
