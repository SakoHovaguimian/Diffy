import Foundation

enum MergeDecision: String, CaseIterable, Codable, Identifiable, Sendable {

    case unresolved = "Unresolved"
    case yours = "Yours"
    case theirs = "Theirs"
    case both = "Yours, then theirs"
    case bothTheirsFirst = "Theirs, then yours"
    case base = "Keep base"
    case edited = "Edited manually"

    var id: String { self.rawValue }

}
