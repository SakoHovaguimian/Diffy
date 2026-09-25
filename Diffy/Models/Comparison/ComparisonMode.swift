import Foundation

enum ComparisonMode: String, CaseIterable, Identifiable {

    case workingTree = "Working tree"
    case staged = "Staged changes"
    case branches = "Branches"
    case commits = "Commits"
    case history = "File history"
    case pullRequests = "Pull requests"
    case merge = "Merge"
    case folders = "Folders"

    var id: String { self.rawValue }

    /// Presentation copy is separate from raw values stored in preferences and review data.
    var displayName: String {

        switch self {

        case .workingTree: "Working Tree"
        case .staged: "Staged Changes"
        case .branches: "Branches"
        case .commits: "Commits"
        case .history: "File History"
        case .pullRequests: "Pull Requests"
        case .merge: "Merge"
        case .folders: "Folders"

        }

    }

    var symbol: String {

        switch self {

        case .workingTree: "pencil.line"
        case .staged: "tray.and.arrow.down"
        case .branches: "arrow.triangle.branch"
        case .commits: "clock.arrow.circlepath"
        case .history: "clock"
        case .pullRequests: "arrow.triangle.pull"
        case .merge: "arrow.triangle.merge"
        case .folders: "folder"

        }

    }

    var tabTitle: String {

        switch self {

        case .workingTree: "Working Tree"
        case .staged: "Staged"
        case .branches: "Branches"
        case .commits: "Commits"
        case .history: "History"
        case .pullRequests: "Pull Requests"
        case .merge: "Conflicts"
        case .folders: "Folders"

        }

    }

    /// Modes whose comparison is chosen with the source bar.
    var usesSourcePicker: Bool {
        self == .branches || self == .commits
    }

}
