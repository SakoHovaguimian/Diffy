import Foundation

struct AppearancePreferences: Codable, Equatable {

    var theme: ThemeSelection = .light
    var accentHex: String = "7862D9"
    var density: String = "Comfortable"
    var cornerRadius: Double = 8
    var animations: Bool = true
    var sidebarWidth: Double = 240
    var transparency: Bool = false

}
