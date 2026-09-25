import Foundation

struct RiskChunkResponse: Codable, Sendable {
    let assessments: [RiskChunkAssessment]
}
