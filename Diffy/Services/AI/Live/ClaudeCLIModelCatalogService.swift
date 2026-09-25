import Foundation

struct ClaudeCLIModelCatalogService: Sendable {

    func models(executable: URL, environment: [String: String]) async throws -> AIModelCatalog {

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("diffy-models-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let requestID = "diffy-models"
        let request: [String: Any] = [
            "type": "control_request",
            "request_id": requestID,
            "request": ["subtype": "initialize"]
        ]
        var input = try JSONSerialization.data(withJSONObject: request)
        input.append(UInt8(ascii: "\n"))

        let data = try await AIControlRequestRunner().run(
            executable: executable,
            arguments: [
                "-p", "--input-format", "stream-json", "--output-format", "stream-json", "--verbose",
                "--safe-mode", "--no-session-persistence", "--permission-mode", "plan", "--tools", ""
            ],
            request: input,
            requestID: requestID,
            directory: directory,
            environment: environment
        )

        guard let outer = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let envelope = outer["response"] as? [String: Any],
              envelope["subtype"] as? String == "success",
              let response = envelope["response"] as? [String: Any],
              let records = response["models"] as? [[String: Any]] else {
            throw AIReviewError.unavailable("Claude Code could not report its models. Check its sign-in or update the installed tool.")
        }

        var seen = Set<String>()
        var defaultID: String?
        let IDs = records.compactMap { record -> String? in

            let value = record["value"] as? String
            let resolved = record["resolvedModel"] as? String
            let ID = [resolved, value].compactMap { $0 }.first(where: AIModelIdentifier.isValid)
            guard let ID else { return nil }

            if value == "default" { defaultID = ID }
            return seen.insert(ID).inserted ? ID : nil

        }
        let limited = Array(IDs.prefix(100))

        guard !limited.isEmpty else {
            throw AIReviewError.unavailable("Claude Code reported no usable models. Check its sign-in or update the installed tool.")
        }

        return AIModelCatalog(
            modelIDs: limited,
            recommendedModelID: defaultID ?? limited.first,
            sourceDescription: "Installed Claude Code reported models",
            notice: "Claude Code reports available selections; access can still depend on the signed-in account."
        )

    }
}
