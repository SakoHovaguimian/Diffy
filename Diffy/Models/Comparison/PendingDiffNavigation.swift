import Foundation

struct PendingDiffNavigation: Identifiable {
    let id = UUID()
    let destination: DiffNavigationDestination
}

enum DiffNavigationDestination {
    case overview
    case dashboard
    case file(projectID: String, fileID: String, mode: ComparisonMode)
    case mode(ComparisonMode)
    case project(projectID: String, tab: ProjectNavigationTab)
    case annotation(CodeAnnotation)
}

enum DiffNavigationDecision {
    case apply
    case discard
    case cancel
}
