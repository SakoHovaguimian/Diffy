import Foundation

enum MockFileFixtures {

    static func files(projectID: String, language: String) -> [DiffFile] {

        if language == "TypeScript" {
            return backendFiles(projectID: projectID)
        }

        let suffix = "swift"

        return [
            file(projectID, "Sources/DesignSystem/ThemeRegistry.\(suffix)", .modified, 2, lines: MockCodeFixtures.themeLines),
            file(projectID, "Sources/DesignSystem/ThemeColors.\(suffix)", .added, 7, lines: MockCodeFixtures.colorLines),
            file(projectID, "Sources/Components/PrimaryButton.\(suffix)", .modified, 12, staged: true, lines: MockCodeFixtures.buttonLines),
            file(projectID, "Sources/Navigation/NavigationService.\(suffix)", .conflicted, 18, lines: MockCodeFixtures.navigationLines),
            file(projectID, "Sources/Models/Appearance.\(suffix)", .renamed, 32, original: "Sources/Models/ThemeSettings.\(suffix)", lines: MockCodeFixtures.colorLines),
            file(projectID, "Sources/Extensions/Color+Hex.\(suffix)", .moved, 48, original: "Sources/Helpers/Color+Hex.\(suffix)", lines: MockCodeFixtures.buttonLines),
            file(projectID, "Resources/Brand/Welcome.png", .modified, 5, kind: .image),
            file(projectID, "Resources/Brand/Logo.png", .added, 22, kind: .image),
            file(projectID, "Resources/Fonts/Display.woff2", .modified, 90, kind: .binary),
            file(projectID, "Resources/legacy-theme.json", .removed, 125, lines: MockCodeFixtures.removedLines),
            file(projectID, "Package.swift", .identical, 480, lines: MockCodeFixtures.packageLines),
            file(projectID, "README.md", .modified, 65, staged: true, lines: MockCodeFixtures.readmeLines)
        ]

    }

    private static func backendFiles(projectID: String) -> [DiffFile] {

        [
            file(projectID, "src/services/userService.ts", .modified, 2, lines: MockBackendCodeFixtures.serviceLines),
            file(projectID, "src/models/userQuery.ts", .added, 7, lines: MockBackendCodeFixtures.modelLines),
            file(projectID, "src/repositories/userRepo.ts", .modified, 12, staged: true, lines: MockBackendCodeFixtures.serviceLines),
            file(projectID, "src/services/navigationService.ts", .conflicted, 18, lines: MockBackendCodeFixtures.serviceLines),
            file(projectID, "src/models/theme.ts", .renamed, 32, original: "src/models/themeSettings.ts", lines: MockBackendCodeFixtures.modelLines),
            file(projectID, "public/welcome.png", .modified, 5, kind: .image),
            file(projectID, "src/legacy-settings.json", .removed, 125, lines: MockCodeFixtures.removedLines),
            file(projectID, "README.md", .modified, 65, staged: true, lines: MockCodeFixtures.readmeLines)
        ]

    }

    private static func file(
        _ projectID: String,
        _ path: String,
        _ status: FileChangeStatus,
        _ minutes: Int,
        staged: Bool = false,
        original: String? = nil,
        kind: ComparisonFileKind = .text,
        lines: [DiffLine] = []
    ) -> DiffFile {

        DiffFile(
            id: "\(projectID):\(path)",
            path: path,
            originalPath: original,
            status: status,
            kind: kind,
            isStaged: staged,
            lastEditedAt: Date().addingTimeInterval(-Double(minutes * 60)),
            size: max(256, lines.count * 72),
            lines: lines
        )

    }

}
