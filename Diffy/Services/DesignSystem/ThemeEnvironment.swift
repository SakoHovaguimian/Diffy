import SwiftUI

private struct DiffyThemeKey: EnvironmentKey {

    static let defaultValue = DiffyTheme.resolve(.porcelain, system: .light, accentHex: "7862D9")

}

extension EnvironmentValues {

    var diffyTheme: DiffyTheme {

        get { self[DiffyThemeKey.self] }
        set { self[DiffyThemeKey.self] = newValue }

    }

}
