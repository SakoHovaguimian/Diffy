import Foundation

struct RiskItem: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let attention: RiskAttention
    let whyFlagged: String
    let evidence: [String]
    let files: [String]
    let symbols: [String]
    let inspect: [String]
    let confidence: RiskConfidence
    let uncertainty: String
}
