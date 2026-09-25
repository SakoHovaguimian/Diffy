import Foundation

struct RiskFileAssessment: Codable, Hashable, Identifiable, Sendable {
    let path: String
    let attention: RiskAttention
    let summary: String
    let factors: [String]
    let evidence: [String]
    let inspect: [String]
    let confidence: RiskConfidence
    let uncertainty: String

    var id: String { self.path }
}
