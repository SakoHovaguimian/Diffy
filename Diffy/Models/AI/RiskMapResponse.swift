import Foundation

struct RiskMapResponse: Codable, Hashable, Sendable {
    let title: String
    let overview: String
    let blastRadius: String?
    let blastRadiusLevel: RiskAttention?
    let fileAssessments: [RiskFileAssessment]?
    let risks: [RiskItem]
}
