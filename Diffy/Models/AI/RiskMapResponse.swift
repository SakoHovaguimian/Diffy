import Foundation

struct RiskMapResponse: Codable, Hashable, Sendable {
    let title: String
    let overview: String
    let risks: [RiskItem]
}
