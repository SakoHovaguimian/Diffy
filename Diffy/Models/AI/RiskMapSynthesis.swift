import Foundation

struct RiskMapSynthesis: Codable, Sendable {
    let title: String
    let overview: String
    let blastRadius: String
    let blastRadiusLevel: RiskAttention
    let risks: [RiskItem]
}
