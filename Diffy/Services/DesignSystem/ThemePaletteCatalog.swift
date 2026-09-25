import SwiftUI

enum ThemePaletteCatalog {

    static func palette(for selection: ThemeSelection, system: ColorScheme) -> ThemePalette {

        switch selection {
        case .light:
            return .light

        case .safira:
            return .safira

        case .adonisLight:
            return .adonisLight

        case .adonisPlusDark:
            return .adonisPlusDark

        case .catppuccinDarkPro:
            return .catppuccinDarkPro

        case .catppuccinFrappe:
            return .catppuccinFrappe

        case .catppuccinMacchiato:
            return .catppuccinMacchiato

        case .catppuccinMocha:
            return .catppuccinMocha

        case .enhancedDark:
            return .enhancedDark

        case .palenight:
            return .palenight

        case .tokyoNight:
            return .tokyoNight

        case .transylvanianTwilight:
            return .transylvanianTwilight

        case .system:
            return system == .dark ? .safira : .light
        }

    }

}
