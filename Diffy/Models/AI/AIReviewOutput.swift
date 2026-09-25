import Foundation

enum AIReviewOutput: Codable, Hashable, Sendable {
    case learningPath(LearningPathResponse)
    case architectureMap(ArchitectureMapResponse)
    case riskMap(RiskMapResponse)

    var visualizationType: AIVisualization {

        switch self {

        case .learningPath: .learningPath
        case .architectureMap: .architectureMap
        case .riskMap: .riskMap

        }

    }
}
