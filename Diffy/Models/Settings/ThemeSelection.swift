import Foundation

enum ThemeSelection: String, CaseIterable, Identifiable, Codable {

    case light = "Light"
    case adonisLight = "Adonis Light"
    case safira = "Safira"
    case adonisPlusDark = "Adonis+ Dark"
    case catppuccinDarkPro = "Catppuccin Dark Pro"
    case catppuccinFrappe = "Catppuccin Frappé"
    case catppuccinMacchiato = "Catppuccin Macchiato"
    case catppuccinMocha = "Catppuccin Mocha"
    case enhancedDark = "Enhanced Dark Theme"
    case palenight = "Palenight Theme"
    case tokyoNight = "Tokyo Night"
    case transylvanianTwilight = "Transylvanian Twilight"
    case system = "System"

    var id: String { self.rawValue }

    var displayName: String { self.rawValue }

    init(from decoder: Decoder) throws {

        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        if value == "Porcelain" {
            self = .light
            return
        }

        guard let selection = ThemeSelection(rawValue: value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown theme selection: \(value)"
            )
        }

        self = selection

    }

    func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)

    }

}
