import Foundation

struct ArchitectureMapResponse: Codable, Hashable, Sendable {
    let title: String
    let overview: String
    let nodes: [ArchitectureNode]
    let edges: [ArchitectureEdge]
}
