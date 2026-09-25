import Foundation

/// Converts provider failures to safe, useful UI copy. Provider error messages can
/// contain request fragments, so only status and documented error codes are read.
enum AIProviderFailureMapper {

    static func httpFailure(
        provider: AIProviderKind,
        statusCode: Int,
        data: Data
    ) -> AIReviewError {

        let code = errorCode(in: data)

        switch statusCode {

        case 400, 422:
            return badRequest(provider: provider, code: code)

        case 401:
            return .unavailable("\(provider.title) rejected the API key. Check it in Settings → AI.")

        case 403:
            return .unavailable("\(provider.title) denied access. Check the API key's project permissions and model access.")

        case 404:
            return .unavailable("\(provider.title) could not find this model. Choose an available model in Settings → AI.")

        case 408, 409:
            return .unavailable("\(provider.title) could not finish this request. Wait a moment and retry.")

        case 413:
            return .unavailable("\(provider.title) rejected the request size. Select fewer files or notes and retry.")

        case 429:
            return rateLimit(provider: provider, code: code)

        case 500...599:
            return .unavailable("\(provider.title) is temporarily unavailable (HTTP \(statusCode)). Retry later.")

        default:
            return .unavailable("\(provider.title) rejected the request (HTTP \(statusCode)). Check the model and retry.")

        }

    }

    static func connectionFailure(provider: AIProviderKind, error: Error) -> AIReviewError {

        guard let urlError = error as? URLError else {
            return .unavailable("Could not connect to \(provider.title). Check your network and retry.")
        }

        switch urlError.code {

        case .notConnectedToInternet:
            return .unavailable("You appear to be offline. Connect to the internet and retry \(provider.title).")

        case .timedOut:
            return .unavailable("\(provider.title) timed out. Select fewer files or notes, or retry later.")

        case .cannotFindHost, .dnsLookupFailed:
            return .unavailable("Could not find \(provider.title)'s API host. Check your network or DNS settings.")

        case .cannotConnectToHost, .networkConnectionLost:
            return .unavailable("The connection to \(provider.title) was interrupted. Retry when the network is stable.")

        case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot:
            return .unavailable("Could not establish a secure connection to \(provider.title). Check the network's certificate settings.")

        default:
            return .unavailable("Could not connect to \(provider.title). Check your network and retry.")

        }

    }

    private static func badRequest(provider: AIProviderKind, code: String?) -> AIReviewError {

        switch code {

        case "invalid_json_schema", "invalid_schema", "schema_validation_error":
            return .unavailable("\(provider.title) rejected Diffy's structured response schema. Try another model or update Diffy.")

        case "model_not_found", "model_not_supported", "unsupported_model":
            return .unavailable("This \(provider.title) model is unavailable or does not support structured output. Choose another model.")

        case "context_length_exceeded", "input_too_long":
            return .unavailable("The selected PR context exceeds this model's limit. Select fewer files or notes.")

        default:
            return .unavailable("\(provider.title) rejected the request. Check that the model is available for this API and retry.")

        }

    }

    private static func rateLimit(provider: AIProviderKind, code: String?) -> AIReviewError {

        if let code,
           ["insufficient_quota", "quota_exceeded", "billing_hard_limit_reached", "resource_exhausted"].contains(code) {
            return .unavailable("\(provider.title) quota is exhausted. Check the provider account's billing and usage limits.")
        }

        return .unavailable("\(provider.title) rate limit reached. Wait before retrying or choose another model.")

    }

    private static func errorCode(in data: Data) -> String? {

        guard data.count <= 64_000,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = object["error"] as? [String: Any] else {
            return nil
        }

        let value = error["code"] as? String
            ?? error["type"] as? String
            ?? error["status"] as? String
        return value?.lowercased()

    }
}
