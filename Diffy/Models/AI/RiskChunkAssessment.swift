import Foundation

struct RiskChunkAssessment: Codable, Sendable {
    let id: String
    let attention: RiskAttention
    let summary: String
    let factors: [String]
    let evidence: [String]
    let inspect: [String]
    let confidence: RiskConfidence
    let uncertainty: String
}
