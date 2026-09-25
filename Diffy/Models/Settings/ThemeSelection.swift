import Foundation

enum ThemeSelection: String, Codable, CaseIterable, Identifiable {
    case safira = "Safira"
    case porcelain = "Porcelain"
    case system = "System"

    var id: String { self.rawValue }
}
