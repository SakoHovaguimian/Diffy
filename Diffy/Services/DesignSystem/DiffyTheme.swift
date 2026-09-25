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
        self.accent.opacity(self.isDark ? 0.20 : 0.09)
    }

    static func resolve(_ selection: ThemeSelection,
                        system: ColorScheme,
                        accentHex: String) -> DiffyTheme {

        let isDark = selection == .safira || (selection == .system && system == .dark)
        return isDark ? self.safira(accentHex: accentHex) : self.porcelain(accentHex: accentHex)

    }

    private static func porcelain(accentHex: String) -> DiffyTheme {

        DiffyTheme(
            isDark: false,
            background: Color(hex: "F6F8FA"),
            sidebar: Color(hex: "F0F2F5"),
            surface: Color(hex: "FFFFFF"),
            elevated: Color(hex: "F7F8FB"),
            text: Color(hex: "303540"),
            secondaryText: Color(hex: "79818E"),
            border: Color(hex: "E3E6ED"),
            accent: Color(hex: accentHex),
            added: Color(hex: "25886C"),
            removed: Color(hex: "D05B72"),
            changed: Color(hex: "4D83C3"),
            modified: Color(hex: "BA8740"),
            keyword: Color(hex: "E84994"),
            type: Color(hex: "8D60D7"),
            string: Color(hex: "66962B"),
            comment: Color(hex: "98A1AD")
        )

    }

    private static func safira(accentHex: String) -> DiffyTheme {

        DiffyTheme(
            isDark: true,
            background: Color(hex: "161D26"),
            sidebar: Color(hex: "0F1922"),
            surface: Color(hex: "1A2430"),
            elevated: Color(hex: "202C3A"),
            text: Color(hex: "DCDEDF"),
            secondaryText: Color(hex: "8F9BAA"),
            border: Color(hex: "2B3848"),
            accent: Color(hex: accentHex),
            added: Color(hex: "80D6A2"),
            removed: Color(hex: "FD8194"),
            changed: Color(hex: "85B5EE"),
            modified: Color(hex: "EDBE63"),
            keyword: Color(hex: "FF9BCB"),
            type: Color(hex: "A8ACF5"),
            string: Color(hex: "B7D88C"),
            comment: Color(hex: "738398")
        )

    }

}
