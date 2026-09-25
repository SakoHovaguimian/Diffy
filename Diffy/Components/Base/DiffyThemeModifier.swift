import SwiftUI

struct DiffyThemeModifier: ViewModifier {

    @Environment(\.colorScheme) private var systemScheme
    @EnvironmentObject private var settings: SettingsViewModel

    func body(content: Content) -> some View {

        let appearance = self.settings.appearance
        let theme = DiffyTheme.resolve(appearance.theme, system: self.systemScheme, accentHex: appearance.accentHex)
        let scheme: ColorScheme? = appearance.theme == .system ? nil : (theme.isDark ? .dark : .light)

        content
            .environment(\.diffyTheme, theme)
            .foregroundStyle(theme.text)
            .tint(theme.accent)
            .preferredColorScheme(scheme)
            .background(theme.background)

    }

}

#Preview {

    Text("Diffy theme")
    .padding(24)
    .withMockPreviews()

}

extension View {

    func diffyStyle() -> some View {
        self.modifier(DiffyThemeModifier())
    }

}
