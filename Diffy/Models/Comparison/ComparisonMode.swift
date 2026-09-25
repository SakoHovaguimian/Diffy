import Foundation

enum ComparisonMode: String, CaseIterable, Identifiable {

    case workingTree = "Working tree"
    case staged = "Staged changes"
    case branches = "Branches"
    case commits = "Commits"
    case folders = "Folders"
    case history = "File history"
    case merge = "Merge"

    var id: String { self.rawValue }

    var symbol: String {

        switch self {

        case .workingTree: "pencil.line"
        case .staged: "tray.and.arrow.down"
        case .branches: "arrow.triangle.branch"
        case .commits: "clock.arrow.circlepath"
        case .folders: "folder"
        case .history: "clock"
        case .merge: "arrow.triangle.merge"

        }

    }

}
