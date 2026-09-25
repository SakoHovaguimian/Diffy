import Foundation

/// A single API boundary for the three providers. Provider-specific wire formats
/// are translated into the same strict Diffy response models.
struct LiveAIProvider: AIProvider {

    let credentialStore: any AICredentialStoreProtocol

    func generate<Response: Decodable & Sendable>(
        request: AIRequest,
        responseType: Response.Type
    ) async throws -> Response {

        guard AIModelIdentifier.isValid(request.model) else {
            throw AIReviewError.unavailable("Choose a valid model identifier.")
        }

        let key = try await self.credentialStore.apiKey(for: request.provider)
        let text: String

        switch request.provider {

        case .openAI: text = try await self.openAIText(for: request, key: key)
        case .anthropic: text = try await self.anthropicText(for: request, key: key)
        case .gemini: text = try await self.geminiText(for: request, key: key)

        }

        guard let data = text.data(using: .utf8) else {
            throw AIReviewError.invalidResponse("The provider did not return the requested structure.")
        }

        try AIJSONShapeValidator.validate(data, against: request.schema)

        guard let response = try? JSONDecoder().decode(responseType, from: data) else {
            throw AIReviewError.invalidResponse("The provider did not return the requested structure.")
        }

        return response

    }

    // MARK: - Provider Requests

    private func openAIText(for request: AIRequest, key: String) async throws -> String {

        let body: [String: Any] = [
            "model": request.model,
            "store": false,
            "max_output_tokens": request.maxOutputTokens,
            "input": [
                ["role": "system", "content": request.systemPrompt],
                ["role": "user", "content": request.userPrompt]
            ],
            "text": ["format": [
                "type": "json_schema",
                "name": request.schema.name,
                "strict": true,
                "schema": request.schema.jsonObject
            ]]
        ]

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw AIReviewError.requestFailed
        }

        let json = try await self.postJSON(
            to: url,
            headers: ["Authorization": "Bearer \(key)"],
            body: body,
            provider: .openAI
        )

        guard json["status"] as? String == "completed" else {

            let reason = (json["incomplete_details"] as? [String: Any])?["reason"] as? String
            if reason == "max_output_tokens" {
                throw AIReviewError.unavailable("OpenAI reached this model's output limit. Select fewer files or notes and retry.")
            }
            if reason == "content_filter" {
                throw AIReviewError.unavailable("OpenAI could not complete this analysis because of a content restriction.")
            }
            throw AIReviewError.incompleteResponse

        }

        guard let output = json["output"] as? [[String: Any]] else {
            throw AIReviewError.invalidResponse("OpenAI did not return a response body.")
        }

        let blocks = output.flatMap { $0["content"] as? [[String: Any]] ?? [] }

        if blocks.contains(where: { $0["type"] as? String == "refusal" }) {
            throw AIReviewError.unavailable("OpenAI declined to analyze this content. Try a narrower question or file selection.")
        }

        let text = blocks.compactMap { block in
            block["type"] as? String == "output_text" ? block["text"] as? String : nil
        }.joined()
        guard !text.isEmpty else { throw AIReviewError.invalidResponse("OpenAI returned no structured text.") }
        return text

    }

    private func anthropicText(for request: AIRequest, key: String) async throws -> String {

        let body: [String: Any] = [
            "model": request.model,
            "max_tokens": request.maxOutputTokens,
            "system": request.systemPrompt,
            "messages": [["role": "user", "content": request.userPrompt]],
            "output_config": ["format": [
                "type": "json_schema",
                "schema": request.schema.jsonObject
            ]]
        ]

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AIReviewError.requestFailed
        }

        let json = try await self.postJSON(
            to: url,
            headers: ["x-api-key": key, "anthropic-version": "2023-06-01"],
            body: body,
            provider: .anthropic
        )

        guard json["stop_reason"] as? String == "end_turn" else {

            if json["stop_reason"] as? String == "max_tokens" {
                throw AIReviewError.unavailable("Anthropic reached this model's output limit. Select fewer files or notes and retry.")
            }
            if json["stop_reason"] as? String == "refusal" {
                throw AIReviewError.unavailable("Anthropic declined to analyze this content. Try a narrower question or file selection.")
            }
            throw AIReviewError.incompleteResponse

        }

        guard let blocks = json["content"] as? [[String: Any]] else {
            throw AIReviewError.invalidResponse("Anthropic did not return a response body.")
        }

        let text = blocks.compactMap { block in
            block["type"] as? String == "text" ? block["text"] as? String : nil
        }.joined()
        guard !text.isEmpty else { throw AIReviewError.invalidResponse("Anthropic returned no structured text.") }
        return text

    }

    private func geminiText(for request: AIRequest, key: String) async throws -> String {

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(request.model):generateContent") else {
            throw AIReviewError.requestFailed
        }
        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": request.systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": request.userPrompt]]]],
            "generationConfig": [
                "responseFormat": ["text": [
                    "mimeType": "application/json",
                    "schema": request.schema.jsonObject
                ]],
                "maxOutputTokens": request.maxOutputTokens
            ]
        ]
        let json = try await self.postJSON(
            to: url,
            headers: ["x-goog-api-key": key],
            body: body,
            provider: .gemini
        )

        guard let candidate = (json["candidates"] as? [[String: Any]])?.first else {

            let blockReason = (json["promptFeedback"] as? [String: Any])?["blockReason"] as? String
            if blockReason != nil {
                throw AIReviewError.unavailable("Gemini could not analyze this content because of a prompt restriction.")
            }
            throw AIReviewError.invalidResponse("Gemini returned no response candidate.")

        }

        guard candidate["finishReason"] as? String == "STOP" else {

            let reason = candidate["finishReason"] as? String
            if reason == "MAX_TOKENS" {
                throw AIReviewError.unavailable("Gemini reached this model's output limit. Select fewer files or notes and retry.")
            }
            if let reason,
               ["SAFETY", "RECITATION", "BLOCKLIST", "PROHIBITED_CONTENT"].contains(reason) {
                throw AIReviewError.unavailable("Gemini could not complete this analysis because of a content restriction.")
            }
            throw AIReviewError.incompleteResponse

        }

        guard let content = candidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw AIReviewError.invalidResponse("Gemini did not return a response body.")
        }

        let text = parts.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw AIReviewError.invalidResponse("Gemini returned no structured text.") }
        return text

    }

    // MARK: - Shared HTTP Boundary

    private func postJSON(
        to url: URL,
        headers: [String: String],
        body: [String: Any],
        provider: AIProviderKind
    ) async throws -> [String: Any] {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 120
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

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
            (data, response) = try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { throw CancellationError() }
            throw AIProviderFailureMapper.connectionFailure(provider: provider, error: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIReviewError.unavailable("\(provider.title) returned an unreadable network response. Retry the request.")
        }

        guard data.count <= 4_000_000 else {
            throw AIReviewError.unavailable("\(provider.title) returned more data than Diffy can read. Select fewer files or notes.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIProviderFailureMapper.httpFailure(provider: provider, statusCode: httpResponse.statusCode, data: data)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIReviewError.invalidResponse("\(provider.title) returned a non-JSON response.")
        }

        return json

    }

}
