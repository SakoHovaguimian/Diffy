import Foundation

enum MergeDecision: String, CaseIterable, Identifiable {
    case unresolved = "Unresolved"
    case yours = "Yours"
    case theirs = "Theirs"
    case both = "Yours, then theirs"
    case base = "Keep base"
    case edited = "Edited manually"

    var id: String { self.rawValue }
}
