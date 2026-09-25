import Foundation

struct LiveAPIModelCatalogService: Sendable {

    let credentialStore: any AICredentialStoreProtocol

    func models(for provider: AIProviderKind) async throws -> AIModelCatalog {

        let key = try await self.credentialStore.apiKey(for: provider)

        switch provider {

        case .openAI: return try await self.openAIModels(key: key)
        case .anthropic: return try await self.anthropicModels(key: key)
        case .gemini: return try await self.geminiModels(key: key)

        }

    }

    // MARK: - Provider Lists

    private func openAIModels(key: String) async throws -> AIModelCatalog {

        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            throw AIReviewError.requestFailed
        }

        let data = try await self.get(url, provider: .openAI, headers: ["Authorization": "Bearer \(key)"])
        let page = try self.decode(OpenAIModelPage.self, from: data)
        let IDs = self.unique(page.data.map(\.id).filter(self.isPlausibleOpenAITextModel))
        let limited = Array(IDs.prefix(200))
        let recommended = ["gpt-5.5", "gpt-5.4", "gpt-5.4-mini"].first(where: limited.contains) ?? limited.first

        return AIModelCatalog(
            modelIDs: limited,
            recommendedModelID: recommended,
            sourceDescription: "OpenAI API model list",
            notice: self.notice(
                "The API lists accessible IDs but does not identify which support Diffy's strict JSON format.",
                truncated: IDs.count > limited.count
            )
        )

    }

    private func anthropicModels(key: String) async throws -> AIModelCatalog {

        var IDs: [String] = []
        var cursor: String?
        var hasMore = false
        var uncertainCapabilities = false

        for _ in 0..<3 {

            try Task.checkCancellation()
            let url = try self.pageURL(
                "https://api.anthropic.com/v1/models",
                items: [("limit", "100"), ("after_id", cursor)]
            )
            let data = try await self.get(
                url,
                provider: .anthropic,
                headers: ["x-api-key": key, "anthropic-version": "2023-06-01"]
            )
            let page = try self.decode(AnthropicModelPage.self, from: data)

            for model in page.data where model.id.hasPrefix("claude-") {

                let support = model.capabilities?.structuredOutputs?.supported
                if support == nil { uncertainCapabilities = true }
                if support != false { IDs.append(model.id) }

            }

            hasMore = page.hasMore
            if !hasMore { break }

            guard let next = page.lastID, !next.isEmpty, next != cursor else {
                throw AIReviewError.incompleteResponse
            }

            cursor = next

        }

        let limited = Array(self.unique(IDs).prefix(200))
        let recommended = limited.first(where: { $0.contains("sonnet") }) ?? limited.first
        let caveat = uncertainCapabilities
            ? "Some model records did not state structured-output support; verify the selected model during generation."
            : "The list is scoped to this API key and includes models reporting structured-output support."

        return AIModelCatalog(
            modelIDs: limited,
            recommendedModelID: recommended,
            sourceDescription: "Anthropic API model list",
            notice: self.notice(caveat, truncated: hasMore || IDs.count > limited.count)
        )

    }

    private func geminiModels(key: String) async throws -> AIModelCatalog {

        var IDs: [String] = []
        var cursor: String?
        var hasMore = false

        for _ in 0..<3 {

            try Task.checkCancellation()
            let url = try self.pageURL(
                "https://generativelanguage.googleapis.com/v1beta/models",
                items: [("pageSize", "100"), ("pageToken", cursor)]
            )
            let data = try await self.get(url, provider: .gemini, headers: ["x-goog-api-key": key])
            let page = try self.decode(GeminiModelPage.self, from: data)

            for model in page.models where model.supportedGenerationMethods.contains("generateContent") {

                guard model.name.hasPrefix("models/") else { continue }
                let id = String(model.name.dropFirst("models/".count))
                if self.isPlausibleGeminiTextModel(id) {
                    IDs.append(id)
                }

            }

            cursor = page.nextPageToken?.isEmpty == false ? page.nextPageToken : nil
            hasMore = cursor != nil
            if !hasMore { break }

        }

        let limited = Array(self.unique(IDs).prefix(200))

        return AIModelCatalog(
            modelIDs: limited,
            recommendedModelID: limited.first,
            sourceDescription: "Gemini API model list",
            notice: self.notice(
                "These models support generateContent; the list does not guarantee strict JSON schema support.",
                truncated: hasMore || IDs.count > limited.count
            )
        )

    }

    // MARK: - HTTP and Filtering

    private func get(_ url: URL, provider: AIProviderKind, headers: [String: String]) async throws -> Data {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25
        request.cachePolicy = .reloadIgnoringLocalCacheData
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw AIProviderFailureMapper.connectionFailure(provider: provider, error: error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIReviewError.requestFailed
        }

        guard data.count <= 2_000_000 else {
            throw AIReviewError.unavailable("\(provider.title) returned a model list too large for Diffy to read.")
        }

        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderFailureMapper.httpFailure(provider: provider, statusCode: http.statusCode, data: data)
        }

        return data

    }

    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {

        guard let value = try? JSONDecoder().decode(type, from: data) else {
            throw AIReviewError.invalidResponse("The provider's model list was incomplete.")
        }

        return value

    }

    private func pageURL(_ base: String, items: [(String, String?)]) throws -> URL {

        guard var components = URLComponents(string: base) else {
            throw AIReviewError.requestFailed
        }

        components.queryItems = items.compactMap { name, value in
            value.map { URLQueryItem(name: name, value: $0) }
        }

        guard let url = components.url else {
            throw AIReviewError.requestFailed
        }

        return url

    }

    private func unique(_ IDs: [String]) -> [String] {

        var seen = Set<String>()
        return IDs.filter { AIModelIdentifier.isValid($0) && seen.insert($0).inserted }

    }

    private func isPlausibleOpenAITextModel(_ id: String) -> Bool {

        let isTextFamily = id.hasPrefix("gpt-")
            || id.range(of: "^o[0-9]", options: .regularExpression) != nil
        let excluded = [
            "audio", "realtime", "transcrib", "tts", "image", "video", "embedding",
            "moderation", "search", "chat", "codex"
        ]

        return isTextFamily && !excluded.contains(where: id.contains)

    }

    private func isPlausibleGeminiTextModel(_ id: String) -> Bool {

        let excluded = ["image", "audio", "tts", "live", "embedding"]
        return id.hasPrefix("gemini-") && !excluded.contains(where: id.contains)

    }

    private func notice(_ caveat: String, truncated: Bool) -> String {
        truncated ? caveat + " Diffy showed only the first part of the available list." : caveat
    }
}

private struct OpenAIModelPage: Decodable {
    let data: [OpenAIModelRecord]
}

private struct OpenAIModelRecord: Decodable {
    let id: String
}

private struct AnthropicModelPage: Decodable {
    let data: [AnthropicModelRecord]
    let hasMore: Bool
    let lastID: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case lastID = "last_id"
    }
}

private struct AnthropicModelRecord: Decodable {
    let id: String
    let capabilities: AnthropicCapabilities?
}

private struct AnthropicCapabilities: Decodable {
    let structuredOutputs: AnthropicCapability?

    enum CodingKeys: String, CodingKey {
        case structuredOutputs = "structured_outputs"
    }
}

private struct AnthropicCapability: Decodable {
    let supported: Bool
}

private struct GeminiModelPage: Decodable {
    let models: [GeminiModelRecord]
    let nextPageToken: String?
}

private struct GeminiModelRecord: Decodable {
    let name: String
    let supportedGenerationMethods: [String]
}
