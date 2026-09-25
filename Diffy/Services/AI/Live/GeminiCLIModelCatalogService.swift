import Foundation

struct GeminiCLIModelCatalogService: Sendable {

    func models(executable: URL, environment: [String: String]) async throws -> AIModelCatalog {

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("diffy-models-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let isolated = try GeminiCLIConfiguration.prepare(in: directory, environment: environment)
        let initialize: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "diffy-initialize",
            "method": "initialize",
            "params": [
                "protocolVersion": 1,
                "clientCapabilities": [String: Any](),
                "clientInfo": ["name": "Diffy", "version": "1"]
            ]
        ]
        let newSession: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "diffy-models",
            "method": "session/new",
            "params": ["cwd": directory.path, "mcpServers": [Any]()]
        ]
        let exchanges = try [
            AIControlRequestRunner.Exchange(request: self.line(initialize), responseID: "diffy-initialize"),
            AIControlRequestRunner.Exchange(request: self.line(newSession), responseID: "diffy-models")
        ]

        let data = try await AIControlRequestRunner().run(
            executable: executable,
            arguments: [
                "--acp", "--extensions", "none", "--admin-policy", GeminiCLIConfiguration.policyURL(in: directory).path
            ],
            exchanges: exchanges,
            directory: directory,
            environment: isolated
        )

        guard let envelope = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIReviewError.invalidResponse("Gemini CLI returned an unreadable ACP model catalog.")
        }

        if let error = envelope["error"] as? [String: Any] {
            throw self.catalogError(error)
        }

        guard let result = envelope["result"] as? [String: Any],
              let models = result["models"] as? [String: Any],
              let records = models["availableModels"] as? [[String: Any]] else {
            throw AIReviewError.unavailable("Gemini CLI did not report its model choices. Check sign-in or update the installed tool.")
        }

        var seen = Set<String>()
        let IDs = records.compactMap { record -> String? in

            guard let ID = record["modelId"] as? String,
                  AIModelIdentifier.isValid(ID), seen.insert(ID).inserted else {
                return nil
            }

            return ID

        }
        let limited = Array(IDs.prefix(100))
        guard !limited.isEmpty else {
            throw AIReviewError.unavailable("Gemini CLI reported no usable models. Check sign-in or update the installed tool.")
        }

        let currentID = models["currentModelId"] as? String
        return AIModelCatalog(
            modelIDs: limited,
            recommendedModelID: currentID.flatMap { limited.contains($0) ? $0 : nil } ?? limited.first,
            sourceDescription: "Installed Gemini CLI ACP model choices",
            notice: "Gemini CLI reports model choices; access can still depend on the signed-in account."
        )

    }

    private func line(_ object: [String: Any]) throws -> Data {

        var data = try JSONSerialization.data(withJSONObject: object)
        data.append(UInt8(ascii: "\n"))
        return data

    }

    private func catalogError(_ error: [String: Any]) -> AIReviewError {

        let message = (error["message"] as? String)?.lowercased() ?? ""
        if message.contains("quota") || message.contains("resource has been exhausted") {
            return .unavailable("Gemini CLI account quota is exhausted. Check usage limits, or choose an API route.")
        }

        if message.contains("authentication") || message.contains("sign in") {
            return .unavailable("Gemini CLI needs sign-in before Diffy can list its models. Sign in from Terminal.")
        }

        return .unavailable("Gemini CLI could not list models. Check sign-in, access, and the installed tool version.")

    }
}
