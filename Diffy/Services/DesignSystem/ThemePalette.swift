import SwiftUI

struct ThemePalette {

    let isDark: Bool
    let background: Color
    let sidebar: Color
    let surface: Color
    let elevated: Color
    let text: Color
    let secondaryText: Color
    let border: Color
    let keyword: Color
    let type: Color
    let string: Color
    let comment: Color

    init(
        isDark: Bool,
        background: String,
        sidebar: String,
        surface: String,
        elevated: String,
        text: String,
        secondaryText: String,
        border: String,
        keyword: String,
        type: String,
        string: String,
        comment: String
    ) {

        self.isDark = isDark
        self.background = Color(hex: background)
        self.sidebar = Color(hex: sidebar)
        self.surface = Color(hex: surface)
        self.elevated = Color(hex: elevated)
        self.text = Color(hex: text)
        self.secondaryText = Color(hex: secondaryText)
        self.border = Color(hex: border)
        self.keyword = Color(hex: keyword)
        self.type = Color(hex: type)
        self.string = Color(hex: string)
        self.comment = Color(hex: comment)

    }

}
