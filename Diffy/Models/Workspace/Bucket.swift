import Foundation

struct Bucket: Identifiable, Codable, Hashable {

    let id: String
    var title: String
    var subtitle: String
    var symbol: String
    var accentHex: String
    var usesGradient: Bool = true
    var cornerRadius: Double = 10
    var isExpanded: Bool = true
    var isVisible: Bool = true
    var density: String = "Expanded"
    var defaultBranch: String = "main"

    mutating func enforceDesignDefaults() {

        self.usesGradient = true
        self.isVisible = true
        self.density = "Expanded"
        self.cornerRadius = 10

    }

}
