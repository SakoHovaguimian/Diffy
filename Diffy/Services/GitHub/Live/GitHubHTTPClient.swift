import Foundation

final class GitHubHTTPClient: NSObject, URLSessionTaskDelegate, Sendable {

    let configuration: GitHubAppConfiguration

    init(configuration: GitHubAppConfiguration) {
        self.configuration = configuration
    }

    func request<Value: Decodable & Sendable>(
        _ type: Value.Type,
        path: String,
        token: String? = nil,
        form: [String: String]? = nil,
        web: Bool = false,
        jsonBody: Data? = nil
    ) async throws -> Value {

        let base = web ? self.configuration.webBaseURL : self.configuration.apiBaseURL

        guard let base, let url = URL(string: base.absoluteString + path), url.scheme == "https" else {
            throw GitHubError.notConfigured
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Diffy-macOS", forHTTPHeaderField: "User-Agent")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let form {

            var components = URLComponents()
            components.queryItems = form.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").data(using: .utf8)

        }

        if let jsonBody {

            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonBody

        }

        let session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {

            if jsonBody != nil {
                throw GitHubError.reviewUnavailable("The connection was interrupted before GitHub confirmed the submission.")
            }
            throw GitHubError.offline

        }

        guard let response = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse("")
        }

        if response.statusCode == 422, jsonBody != nil {
            throw GitHubError.reviewUnavailable("GitHub rejected this submission. Check the review state, comment locations, and account permissions. If you already have a pending review on GitHub, finish it there first.")
        }

        try validate(response)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw GitHubError.invalidResponse("Try refreshing this page.")
        }

    }

    private func validate(_ response: HTTPURLResponse) throws {

        switch response.statusCode {

        case 200...299: return
        case 401: throw GitHubError.reauthorizationRequired(accountID: "")
        case 404: throw GitHubError.notFound
        case 403, 429:
            if response.statusCode == 429 || response.value(forHTTPHeaderField: "X-RateLimit-Remaining") == "0" || response.value(forHTTPHeaderField: "Retry-After") != nil {

                let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap(Double.init).map { Date(timeIntervalSince1970: $0) }
                throw GitHubError.rateLimited(resetsAt: reset)

            }

            throw GitHubError.forbidden("This account does not have access. Check the app installation or token permissions on GitHub.")

        default: throw GitHubError.server(status: response.statusCode)

        }

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }

}
