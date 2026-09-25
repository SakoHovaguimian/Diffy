import Foundation

/// Extracts a bounded error message without showing the CLI transcript or request.
enum AICommandDiagnostics {

    static func message(standardError: Data, standardOutput: Data) -> String? {

        let errorText = String(decoding: standardError, as: UTF8.self)
        let lines = errorText.components(separatedBy: .newlines).reversed()
        let structuredError = lines.compactMap { line -> String? in

            guard let start = line.firstIndex(of: "{") else { return nil }
            return Self.structuredMessage(Data(line[start...].utf8))

        }.first
        let outputError = Self.structuredMessage(standardOutput)
        let plainError = lines.first { line in

            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            return trimmed.hasPrefix("error:") || trimmed.hasPrefix("error ") || trimmed.hasPrefix("fatal:")

        }

        guard let message = structuredError ?? outputError ?? plainError else { return nil }
        let detail = Self.sanitized(message)
        guard !detail.isEmpty else { return nil }
        return detail + Self.recoveryHint(for: detail)

    }

    private static func structuredMessage(_ data: Data) -> String? {

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }

        if let error = json["error"] as? String { return error }

        if json["is_error"] as? Bool == true {
            return json["result"] as? String
        }

        if json["type"] as? String == "error" {
            return json["message"] as? String
        }

        return nil

    }

    private static func sanitized(_ message: String) -> String {

        var cleaned = message
            .replacingOccurrences(of: #"\x1B\[[0-?]*[ -/]*[@-~]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\b(?:sk-[A-Za-z0-9_-]+|AIza[A-Za-z0-9_-]+|eyJ[A-Za-z0-9_.-]+|gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b"#, with: "[redacted]", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)(?:bearer|basic)\s+[A-Za-z0-9._~+/=-]+"#, with: "[redacted authorization]", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)([\"']?(?:api[_-]?key|access[_-]?token|refresh[_-]?token|id[_-]?token|authorization)[\"']?\s*[:=]\s*)[\"']?[^\s\"',}]+"#, with: "$1[redacted]", options: .regularExpression)
            .replacingOccurrences(of: #"(https?://)[^\s/@]+@"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"https?://[^\s\"']*\?[^\s\"']*"#, with: "[URL with query redacted]", options: .regularExpression)
            .replacingOccurrences(of: #"[\x00-\x1F\x7F]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        cleaned = cleaned.replacingOccurrences(of: home, with: "~")
        return String(cleaned.prefix(1_000))

    }

    private static func recoveryHint(for message: String) -> String {

        let normalized = message.lowercased()

        if normalized.contains("model") && ["not supported", "not found", "does not exist", "access"].contains(where: normalized.contains) {
            return " Refresh Models for the installed CLI and select a model available to its signed-in account. API and CLI model access can differ."
        }

        if ["not logged in", "not signed in", "unauthorized", "authentication", "token expired"].contains(where: normalized.contains) {
            return " Sign in to this command-line tool in Terminal, then retry. The Provider API connection uses its separate Keychain key."
        }

        if normalized.contains("unexpected argument") || normalized.contains("unknown option") {
            return " Update the installed command-line tool and retry."
        }

        return ""

    }

}
