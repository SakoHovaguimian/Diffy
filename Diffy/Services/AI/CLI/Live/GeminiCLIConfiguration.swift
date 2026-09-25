import Foundation

/// Shared isolation for Gemini generation and prompt-free model discovery.
enum GeminiCLIConfiguration {

    static func prepare(in directory: URL, environment: [String: String]) throws -> [String: String] {

        let runner = AICommandRunner()
        let policy = "[[rule]]\ntoolName = \"*\"\ndecision = \"deny\"\npriority = 999\n"
        try runner.writePrivate(Data(policy.utf8), to: Self.policyURL(in: directory))
        let settingsURL = directory.appendingPathComponent("settings.json")
        try runner.writePrivate(try JSONSerialization.data(withJSONObject: Self.settings()), to: settingsURL)
        var isolated = environment
        isolated["GEMINI_CLI_SYSTEM_SETTINGS_PATH"] = settingsURL.path
        isolated["GEMINI_CLI_SYSTEM_DEFAULTS_PATH"] = settingsURL.path
        return isolated

    }

    static func policyURL(in directory: URL) -> URL {
        directory.appendingPathComponent("deny-tools.toml")
    }

    private static func settings() -> [String: Any] {

        [
            "tools": ["core": [String]()],
            "mcp": ["allowed": [String]()],
            "hooksConfig": ["enabled": false],
            "skills": ["enabled": false],
            "telemetry": ["enabled": false, "logPrompts": false],
            "privacy": ["usageStatisticsEnabled": false],
            "context": [
                "fileName": ".diffy-no-memory-\(UUID().uuidString)", "includeDirectoryTree": false,
                "includeDirectories": [String](), "loadMemoryFromIncludeDirectories": false
            ],
            "experimental": ["enableAgents": false],
            "admin": [
                "secureModeEnabled": true, "extensions": ["enabled": false],
                "mcp": ["enabled": false], "skills": ["enabled": false]
            ]
        ]

    }

}
