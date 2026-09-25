import Foundation

extension AIProviderKind {

    var commandName: String {

        switch self {

        case .openAI: "codex"
        case .anthropic: "claude"
        case .gemini: "gemini"

        }

    }

    var commandTitle: String {

        switch self {

        case .openAI: "Codex CLI"
        case .anthropic: "Claude Code"
        case .gemini: "Gemini CLI"

        }

    }

    var commandSetupURL: URL? {

        switch self {

        case .openAI: URL(string: "https://developers.openai.com/codex/cli")
        case .anthropic: URL(string: "https://code.claude.com/docs/en/setup")
        case .gemini: URL(string: "https://geminicli.com/docs/get-started/installation/")

        }

    }

}
