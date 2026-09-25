import Foundation

struct InstalledCLIProvider: AIProvider {

    private let locator = InstalledAICommandLocator()
    private let runner = AICommandRunner()

    func generate<Response: Decodable & Sendable>(
        request: AIRequest,
        responseType: Response.Type
    ) async throws -> Response {

        guard AIModelIdentifier.isValid(request.model) else {
            throw AIReviewError.unavailable("Choose a valid model ID before using an installed tool.")
        }

        guard let executable = self.locator.executable(for: request.provider) else {
            throw AICommandError.unavailable(request.provider.commandTitle)
        }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("diffy-ai-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }

        try await self.verifyOptions(provider: request.provider, executable: executable, directory: directory)
        try Task.checkCancellation()
        let data: Data

        switch request.provider {

        case .openAI:
            data = try await self.runCodex(request, executable: executable, directory: directory)

        case .anthropic:
            data = try await self.runClaude(request, executable: executable, directory: directory)

        case .gemini:
            data = try await self.runGemini(request, executable: executable, directory: directory)

        }

        try Task.checkCancellation()
        try AIJSONShapeValidator.validate(data, against: request.schema)

        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw AIReviewError.invalidResponse("The installed tool did not return the required JSON structure.")
        }

    }

    private func verifyOptions(provider: AIProviderKind, executable: URL, directory: URL) async throws {

        let arguments = provider == .openAI ? ["exec", "--help"] : ["--help"]
        let output = try await self.runner.run(
            executable: executable,
            arguments: arguments,
            input: Data(),
            directory: directory,
            environment: self.locator.environment,
            timeout: 20
        )
        let help = String(decoding: output, as: UTF8.self)
        let required: [String]

        switch provider {

        case .openAI:
            required = ["--ignore-user-config", "--ignore-rules", "--sandbox", "--ephemeral", "--output-schema"]

        case .anthropic:
            required = ["--safe-mode", "--tools", "--json-schema", "--no-session-persistence", "--strict-mcp-config"]

        case .gemini:
            required = ["--admin-policy", "--extensions", "--output-format", "--approval-mode"]

        }

        guard required.allSatisfy({ help.contains($0) }) else {
            throw AICommandError.incompatible(provider.commandTitle)
        }

    }

    private func schemaData(_ request: AIRequest) throws -> Data {
        try JSONSerialization.data(withJSONObject: request.schema.jsonObject, options: [.sortedKeys])
    }

    private func promptData(_ request: AIRequest) throws -> Data {

        let schema = String(decoding: try self.schemaData(request), as: UTF8.self)
        let prompt = """
        \(request.systemPrompt)

        Analyze only the provided PR context. Do not read files, invoke tools, browse, or change anything.
        Return exactly one JSON object matching this schema, without Markdown fences:
        \(schema)

        \(request.userPrompt)
        """

        return Data(prompt.utf8)

    }

    private func runCodex(_ request: AIRequest, executable: URL, directory: URL) async throws -> Data {

        let schemaURL = directory.appendingPathComponent("schema.json")
        let resultURL = directory.appendingPathComponent("result.json")
        try self.runner.writePrivate(try self.schemaData(request), to: schemaURL)
        var arguments = [
            "exec", "--ignore-user-config", "--ignore-rules", "--ephemeral", "--skip-git-repo-check",
            "--sandbox", "read-only", "--color", "never", "--model", request.model,
            "--output-schema", schemaURL.path, "--output-last-message", resultURL.path,
            "--config", "approval_policy=\"never\"", "--config", "web_search=\"disabled\"",
            "--config", "project_doc_max_bytes=0"
        ]

        for feature in [
            "shell_tool", "unified_exec", "shell_snapshot", "hooks", "plugins", "remote_plugin", "apps",
            "multi_agent", "browser_use", "computer_use", "image_generation", "view_image", "code_mode_host"
        ] {
            arguments += ["--disable", feature]
        }

        arguments.append("-")
        _ = try await self.runner.run(
            executable: executable,
            arguments: arguments,
            input: try self.promptData(request),
            directory: directory,
            environment: self.locator.environment
        )
        guard FileManager.default.fileExists(atPath: resultURL.path) else {
            throw AIReviewError.invalidResponse("Codex completed without a structured result. Try another model or update the installed tool.")
        }

        let reader = try FileHandle(forReadingFrom: resultURL)
        defer { try? reader.close() }
        let data = try reader.read(upToCount: 4_000_001) ?? Data()

        guard data.count <= 4_000_000 else {
            throw AICommandError.oversizedOutput
        }

        guard !data.isEmpty else {
            throw AIReviewError.invalidResponse("Codex returned an empty result. Try a smaller selection or another model.")
        }

        return data

    }

    private func runClaude(_ request: AIRequest, executable: URL, directory: URL) async throws -> Data {

        let schema = String(decoding: try self.schemaData(request), as: UTF8.self)
        let arguments = [
            "--print", "--safe-mode", "--no-session-persistence", "--no-chrome",
            "--tools", "", "--disallowedTools", "mcp__*", "--disable-slash-commands",
            "--strict-mcp-config", "--mcp-config", "{\"mcpServers\":{}}",
            "--setting-sources", "", "--settings", "{\"disableAllHooks\":true}",
            "--permission-mode", "dontAsk", "--output-format", "json",
            "--json-schema", schema, "--model", request.model
        ]
        let data = try await self.runner.run(
            executable: executable,
            arguments: arguments,
            input: try self.promptData(request),
            directory: directory,
            environment: self.locator.environment
        )

        guard let envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              envelope["is_error"] as? Bool != true,
              envelope["subtype"] as? String == "success" else {
            throw AIReviewError.incompleteResponse
        }

        if let output = envelope["structured_output"] as? [String: Any] {
            return try JSONSerialization.data(withJSONObject: output)
        }

        guard let result = envelope["result"] as? String else {
            throw AIReviewError.incompleteResponse
        }

        return Data(result.utf8)

    }

    private func runGemini(_ request: AIRequest, executable: URL, directory: URL) async throws -> Data {

        let policyURL = GeminiCLIConfiguration.policyURL(in: directory)
        let environment = try GeminiCLIConfiguration.prepare(in: directory, environment: self.locator.environment)
        let data = try await self.runner.run(
            executable: executable,
            arguments: [
                "--model", request.model, "--output-format", "json", "--extensions", "none",
                "--approval-mode", "default", "--admin-policy", policyURL.path,
                "--prompt", "Analyze the supplied PR snapshot and return only its required JSON."
            ],
            input: try self.promptData(request),
            directory: directory,
            environment: environment
        )

        guard let envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              envelope["error"] == nil,
              let response = envelope["response"] as? String else {
            throw AIReviewError.incompleteResponse
        }

        return Data(response.utf8)

    }

}
