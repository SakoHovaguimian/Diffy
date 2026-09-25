import Foundation

struct InstalledAICommandLocator: AICommandAvailabilityServiceProtocol {

    func availability(for provider: AIProviderKind) async -> AICommandAvailability {

        let executable = self.executable(for: provider)

        return AICommandAvailability(
            provider: provider,
            executablePath: executable?.path,
            problem: executable == nil ? "Install \(provider.commandTitle), then sign in from Terminal." : nil
        )

    }

    func executable(for provider: AIProviderKind) -> URL? {

        let manager = FileManager.default
        return self.searchDirectories.compactMap { directory in

            let url = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(provider.commandName)
            return manager.isExecutableFile(atPath: url.path) ? url : nil

        }.first

    }

    var searchDirectories: [String] {

        let userDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let environmentPaths = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":") ?? []
        let commonPaths = [
            userDirectory + "/.local/bin", userDirectory + "/.npm-global/bin",
            userDirectory + "/.volta/bin", "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"
        ]

        // Empty and relative PATH entries must not resolve against a repository.
        return Array(NSOrderedSet(array: commonPaths + environmentPaths.filter { $0.hasPrefix("/") }))
            .compactMap { $0 as? String }

    }

    var environment: [String: String] {

        let inherited = ProcessInfo.processInfo.environment
        let allowed = Set(["HOME", "USER", "LOGNAME", "TMPDIR", "LANG", "LC_ALL", "LC_CTYPE"])
        var environment = inherited.filter { allowed.contains($0.key) }
        environment["HOME"] = inherited["HOME"] ?? FileManager.default.homeDirectoryForCurrentUser.path

        // Preserve an explicitly configured credential location without copying shell secrets.
        for name in ["CODEX_HOME", "CLAUDE_CONFIG_DIR"] {
            if let directory = inherited[name], directory.hasPrefix("/") { environment[name] = directory }
        }

        environment["PATH"] = self.searchDirectories.joined(separator: ":")
        environment["NO_COLOR"] = "1"
        environment["TERM"] = "dumb"

        return environment

    }

}
