import SwiftUI

struct DiffyTheme {

    let isDark: Bool
    let background: Color
    let sidebar: Color
    let surface: Color
    let elevated: Color
    let text: Color
    let secondaryText: Color
    let border: Color
    let accent: Color
    let added: Color
    let removed: Color
    let changed: Color
    let modified: Color
    let keyword: Color
    let type: Color
    let string: Color
    let comment: Color

    var selection: Color {
        self.accent.opacity(self.isDark ? 0.20 : 0.17)
    }

    static func resolve(
        _ selection: ThemeSelection,
        system: ColorScheme,
        accentHex: String
    ) -> DiffyTheme {

        let palette = ThemePaletteCatalog.palette(for: selection, system: system)

        return DiffyTheme(
            isDark: palette.isDark,
            background: palette.background,
            sidebar: palette.sidebar,
            surface: palette.surface,
            elevated: palette.elevated,
            text: palette.text,
            secondaryText: palette.secondaryText,
            border: palette.border,
            accent: Color(hex: accentHex),
            added: Color(hex: palette.isDark ? "80D6A2" : "25886C"),
            removed: Color(hex: palette.isDark ? "FD8194" : "D05B72"),
            changed: Color(hex: palette.isDark ? "85B5EE" : "386DAA"),
            modified: Color(hex: palette.isDark ? "EDBE63" : "986B2B"),
            keyword: palette.keyword,
            type: palette.type,
            string: palette.string,
            comment: palette.comment
        )

    }

}
