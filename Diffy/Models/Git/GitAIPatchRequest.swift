import Foundation

/// A reviewed proposal may change only these exact paths at this exact checkout head.
struct GitAIPatchRequest: Sendable {
    let patch: String
    let allowedPaths: [String]
    let expectedHeadSHA: String
}
