import Foundation

enum ArchitectureNodeKind: String, Codable, Hashable, Sendable {
    case view
    case viewModel
    case service
    case api
    case model
    case persistence
    case other
}
