import Foundation

enum MockCodeFixtures {

    // These aligned source pairs are fixtures, not the output of a diff engine.

    static let themeLines: [DiffLine] = aligned([
        ("import SwiftUI", "import SwiftUI"),
        ("", ""),
        ("// MARK: - Theme Registry", "// MARK: - Theme Registry"),
        ("", ""),
        ("@MainActor", "@MainActor"),
        ("final class ThemeRegistry: ObservableObject {", "final class ThemeRegistry: ObservableObject {"),
        ("", ""),
        ("    @Published var theme: Theme = .default", "    @Published private(set) var theme: Theme"),
        (nil, "    private let preferencesService: PreferencesServiceProtocol"),
        ("", ""),
        ("    init() {", "    init(preferencesService: PreferencesServiceProtocol) {"),
        ("", ""),
        ("        self.theme = .default", "        self.preferencesService = preferencesService"),
        (nil, "        self.theme = preferencesService.selectedTheme"),
        ("", ""),
        ("    }", "    }"),
        ("", ""),
        ("    // MARK: - Appearance", "    // MARK: - Appearance"),
        ("", ""),
        ("    func updateTheme(_ theme: Theme) {", "    func updateTheme(_ theme: Theme) {"),
        ("", ""),
        ("        self.theme = theme", "        applyTheme(theme)"),
        (nil, "        savePreference(theme)"),
        ("", ""),
        ("    }", "    }"),
        ("", ""),
        (nil, "    private func applyTheme(_ theme: Theme) {"),
        (nil, "        self.theme = theme"),
        (nil, "    }"),
        (nil, ""),
        (nil, "    private func savePreference(_ theme: Theme) {"),
        (nil, "        self.preferencesService.set(theme: theme)"),
        (nil, "    }"),
        (nil, ""),
        ("}", "}")
    ])

    static let colorLines: [DiffLine] = aligned([
        (nil, "import SwiftUI"), (nil, ""),
        (nil, "struct ThemeColors {"),
        (nil, "    let background: Color"),
        (nil, "    let surface: Color"),
        (nil, "    let accent: Color"),
        (nil, "    let primaryText: Color"),
        (nil, "    let secondaryText: Color"),
        (nil, "}")
    ])

    static let buttonLines: [DiffLine] = aligned([
        ("import SwiftUI", "import SwiftUI"), ("", ""),
        ("struct PrimaryButton: View {", "struct PrimaryButton: View {"),
        ("", ""), ("    let title: String", "    let title: String"),
        ("    let action: () -> Void", "    let action: () -> Void"), ("", ""),
        ("    var body: some View {", "    var body: some View {"), ("", ""),
        ("        Button(title, action: action)", "        Button(title, action: self.action)"),
        ("            .padding(8)", "            .padding(.horizontal, 16)"),
        (nil, "            .padding(.vertical, 10)"),
        ("            .background(Color.blue)", "            .background(self.theme.accent)"),
        ("            .cornerRadius(4)", "            .clipShape(RoundedRectangle(cornerRadius: 8))"),
        ("", ""), ("    }", "    }"), ("", ""), ("}", "}")
    ])

    static let navigationLines: [DiffLine] = aligned([
        ("func openProject(_ project: Project) {", "func openProject(_ project: Project) {"),
        ("", ""),
        ("    self.path.append(project)", "    self.selectedProject = project"),
        (nil, "    self.restoreSelection(for: project)"),
        ("", ""), ("}", "}")
    ])

    static let removedLines: [DiffLine] = aligned([
        ("{", nil), ("    \"theme\": \"legacy\",", nil),
        ("    \"accent\": \"blue\"", nil), ("}", nil)
    ])

    static let packageLines: [DiffLine] = aligned([
        ("// swift-tools-version: 6.0", "// swift-tools-version: 6.0"),
        ("import PackageDescription", "import PackageDescription"),
        ("", ""), ("let package = Package(name: \"Rune\")", "let package = Package(name: \"Rune\")")
    ])

    static let readmeLines: [DiffLine] = aligned([
        ("# Rune", "# Rune"), ("", ""),
        ("A SwiftUI component library.", "A considered design system for SwiftUI."),
        ("", ""), (nil, "## Designed for the details"),
        (nil, "Comfortable spacing. Clear hierarchy. Your own voice.")
    ])

    static func aligned(_ pairs: [(String?, String?)]) -> [DiffLine] {

        var oldNumber = 0
        var newNumber = 0

        return pairs.enumerated().map { index, pair in

            if pair.0 != nil {
                oldNumber += 1
            }

            if pair.1 != nil {
                newNumber += 1
            }

            let status = self.status(left: pair.0, right: pair.1)

            return DiffLine(
                id: index,
                oldNumber: pair.0 == nil ? nil : oldNumber,
                newNumber: pair.1 == nil ? nil : newNumber,
                left: pair.0,
                right: pair.1,
                status: status,
                emphasis: status == .modified ? "self" : nil
            )

        }

    }

    private static func status(left: String?, right: String?) -> FileChangeStatus {

        if left == nil {
            return .added
        }

        if right == nil {
            return .removed
        }

        return left == right ? .identical : .modified

    }

}
