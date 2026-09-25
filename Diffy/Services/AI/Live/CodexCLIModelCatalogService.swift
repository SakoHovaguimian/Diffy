import Foundation

struct CodexCLIModelCatalogService: Sendable {

    func models(executable: URL, environment: [String: String]) async throws -> AIModelCatalog {

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("diffy-models-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let data = try await AICommandRunner().run(
            executable: executable,
            arguments: ["debug", "models", "-c", "model_provider=\"openai\""],
            input: Data(),
            directory: directory,
            environment: environment,
            timeout: 25
        )
        let catalog: CodexModelList

        do {
            catalog = try JSONDecoder().decode(CodexModelList.self, from: data)
        } catch {
            throw AIReviewError.invalidResponse("The installed Codex model catalog could not be read. Update Codex and try again.")
        }

        var seen = Set<String>()
        let IDs = catalog.models.compactMap { model -> String? in

            guard model.visibility == "list",
                  AIModelIdentifier.isValid(model.slug), seen.insert(model.slug).inserted else {
                return nil
            }

            return model.slug

        }
        let limited = Array(IDs.prefix(100))

        guard !limited.isEmpty else {
            throw AIReviewError.unavailable("The installed Codex catalog has no visible supported models. Update Codex or choose another route.")
        }

        return AIModelCatalog(
            modelIDs: limited,
            recommendedModelID: limited.first,
            sourceDescription: "Installed Codex reported models",
            notice: IDs.count > limited.count
                ? "Diffy displayed the first 100 visible Codex models. Account access may vary."
                : "Codex reports visible models; access can still depend on the signed-in account."
        )

    }
}

private struct CodexModelList: Decodable {
    let models: [CodexModelRecord]
}

private struct CodexModelRecord: Decodable {
    let slug: String
    let visibility: String

    enum CodingKeys: String, CodingKey {
        case slug
        case visibility
    }
}
