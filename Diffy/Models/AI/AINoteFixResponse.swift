import Foundation

struct AINoteFixResponse: Codable, Hashable, Sendable {
    let plan: [String]
    let affectedFiles: [String]
    let proposedPatch: String
    let explanation: String
    let uncertainty: String
}
