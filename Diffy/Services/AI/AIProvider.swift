import Foundation

protocol AIProvider: Sendable {
    func generate<Response: Decodable & Sendable>(
        request: AIRequest,
        responseType: Response.Type
    ) async throws -> Response
}
