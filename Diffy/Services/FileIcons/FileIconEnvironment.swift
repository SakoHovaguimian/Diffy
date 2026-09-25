import SwiftUI

private struct FileIconThemeKey: EnvironmentKey {
    static let defaultValue = FileIconTheme.material
}

private struct FileIconServiceKey: EnvironmentKey {
    static let defaultValue: (any FileIconServiceProtocol)? = nil
}

extension EnvironmentValues {

    var fileIconTheme: FileIconTheme {

        get { self[FileIconThemeKey.self] }
        set { self[FileIconThemeKey.self] = newValue }

    }

    var fileIconService: (any FileIconServiceProtocol)? {

        get { self[FileIconServiceKey.self] }
        set { self[FileIconServiceKey.self] = newValue }

    }

}
