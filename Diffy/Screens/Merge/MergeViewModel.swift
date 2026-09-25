import SwiftUI
import Combine

@MainActor
final class MergeViewModel: ViewModel {

    let loggerName = "MERGE_VIEW_MODEL"
    let conflicts: [MergeConflict] = [
        MergeConflict(
            id: 0,
            title: "Restore project navigation",
            base: "func openProject(_ project: Project) {\n\n    self.path.append(project)\n\n}",
            yours: "func openProject(_ project: Project) {\n\n    self.selectedProject = project\n    restoreSelection(for: project)\n\n}",
            theirs: "func openProject(_ project: Project) {\n\n    self.path.append(project)\n    recordRecentProject(project)\n\n}"
        ),
        MergeConflict(
            id: 1,
            title: "Choose the default presentation",
            base: "let defaultLayout: Layout = .list",
            yours: "let defaultLayout: Layout = .tree",
            theirs: "let defaultLayout: Layout = .adaptive"
        ),
        MergeConflict(
            id: 2,
            title: "Preserve the reading position",
            base: "self.scrollPosition = .top",
            yours: "self.scrollPosition = savedPosition",
            theirs: "self.scrollPosition = firstChange"
        )
    ]

    @Published var selectedIndex = 0
    @Published private(set) var results: [Int: String] = [:]
    @Published private(set) var decisions: [Int: MergeDecision] = [:]
    private var undoHistory: [MergeDraftSnapshot] = []

    var conflict: MergeConflict {
        self.conflicts[self.selectedIndex]
    }

    var result: String {
        self.results[self.conflict.id] ?? self.conflict.base
    }

    var resolvedCount: Int {
        self.decisions.values.filter { $0 != .unresolved }.count
    }

    var canUndo: Bool {
        !self.undoHistory.isEmpty
    }

    func sourceText(_ conflict: MergeConflict, side: SourceSide) -> String {

        switch side {

        case .yours: conflict.yours
        case .theirs: conflict.theirs
        case .result: self.results[conflict.id] ?? conflict.base
        default: conflict.base

        }

    }

    func startLine(for side: SourceSide) -> Int {

        self.conflicts.prefix(self.selectedIndex).reduce(1) { line, conflict in
            line + sourceText(conflict, side: side).components(separatedBy: "\n").count + 1
        }

    }

    // MARK: - Conflict Resolution

    func accept(_ decision: MergeDecision) {

        rememberState()

        switch decision {

        case .yours:
            self.results[self.conflict.id] = self.conflict.yours

        case .theirs:
            self.results[self.conflict.id] = self.conflict.theirs

        case .both:
            self.results[self.conflict.id] = self.conflict.yours + "\n\n" + self.conflict.theirs

        case .bothTheirsFirst:
            self.results[self.conflict.id] = self.conflict.theirs + "\n\n" + self.conflict.yours

        case .base, .unresolved:
            self.results[self.conflict.id] = self.conflict.base

        case .edited:
            break

        }

        self.decisions[self.conflict.id] = decision

    }

    func editResult(_ text: String) {

        rememberState()
        self.results[self.conflict.id] = text
        self.decisions[self.conflict.id] = .unresolved

    }

    func markResolved() {

        rememberState()
        self.decisions[self.conflict.id] = .edited

    }

    func navigate(_ direction: Int) {
        self.selectedIndex = (self.selectedIndex + direction + self.conflicts.count) % self.conflicts.count
    }

    func undo() {

        guard let snapshot = self.undoHistory.popLast() else {
            return
        }

        self.results = snapshot.results
        self.decisions = snapshot.decisions

    }

    func reset() {

        rememberState()
        self.results = [:]
        self.decisions = [:]

    }

    private func rememberState() {

        self.undoHistory.append(MergeDraftSnapshot(results: self.results, decisions: self.decisions))

        if self.undoHistory.count > 100 {
            self.undoHistory.removeFirst()
        }

    }

}
