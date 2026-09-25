import Foundation

struct ArchitectureNode: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let label: String
    let kind: ArchitectureNodeKind
    let change: ArchitectureChangeKind
    let responsibility: String
    let changedFiles: [String]
    let relevantSymbols: [String]
    let whyItMatters: String
}
