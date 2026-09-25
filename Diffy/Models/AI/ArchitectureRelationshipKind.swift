import Foundation

enum ArchitectureRelationshipKind: String, Codable, Hashable, Sendable {
    case dataFlow
    case controlFlow
    case dependency
}
