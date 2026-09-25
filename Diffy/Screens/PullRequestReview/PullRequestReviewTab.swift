import Foundation

enum PullRequestReviewTab: String, CaseIterable, Identifiable {
    case conversation
    case commits
    case filesChanged
    case learningPath
    case architectureMap
    case riskMap
    case aiNotes

    var id: String { self.rawValue }

    var title: String {

        switch self {
        case .conversation: "Conversation"
        case .commits: "Commits"
        case .filesChanged: "Files Changed"
        case .learningPath: "Learning Path"
        case .architectureMap: "Architecture Map"
        case .riskMap: "Risk Map"
        case .aiNotes: "AI Notes"
        }

    }

    var visualization: AIVisualization? {

        switch self {
        case .learningPath: .learningPath
        case .architectureMap: .architectureMap
        case .riskMap: .riskMap
        default: nil
        }

    }
}
