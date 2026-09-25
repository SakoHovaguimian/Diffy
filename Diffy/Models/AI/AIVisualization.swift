import Foundation

enum AIVisualization: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case learningPath
    case architectureMap
    case riskMap

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .learningPath: "Learning Path"
        case .architectureMap: "Architecture Map"
        case .riskMap: "Risk Map"

        }

    }
}
