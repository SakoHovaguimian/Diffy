import Foundation

enum LearningPathExampleKind: String, Codable, Hashable, Sendable {
    case source
    case illustrative

    var title: String {

        switch self {

        case .source: "From The Diff"
        case .illustrative: "Simplified Example"

        }

    }
}
