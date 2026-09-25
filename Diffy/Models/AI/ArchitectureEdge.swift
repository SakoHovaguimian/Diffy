import Foundation

struct ArchitectureEdge: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let sourceID: String
    let targetID: String
    let kind: ArchitectureRelationshipKind
    let label: String
}
