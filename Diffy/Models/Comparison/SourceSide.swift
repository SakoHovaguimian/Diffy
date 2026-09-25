import Foundation

enum SourceSide: String, Codable, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"
    case base = "Base"
    case yours = "Yours"
    case theirs = "Theirs"
    case result = "Result"

    var id: String { self.rawValue }
}
