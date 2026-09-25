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

    /// Presentation copy is separate from raw values stored in preferences and review data.
    var displayName: String {

        switch self {

        case .unresolved: "Unresolved"
        case .yours: "Yours"
        case .theirs: "Theirs"
        case .both: "Yours, Then Theirs"
        case .bothTheirsFirst: "Theirs, Then Yours"
        case .base: "Keep Base"
        case .edited: "Edited Manually"

        }

    }

}
