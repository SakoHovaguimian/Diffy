import SwiftUI
import Combine

@MainActor
final class TextDiffViewModel: ViewModel {

    let loggerName = "TEXT_DIFF_VIEW_MODEL"
    @Published var selectionStart: Int?
    @Published var selectionEnd: Int?
    @Published var selectedSide: SourceSide = .right
    @Published var selectedChangeIndex = 0
    @Published var scrollTarget: Int?
    @Published var search = ""
    @Published var showsSearch = false
    @Published var paneRatio = 0.5

    // MARK: - Source Selection

    func select(_ line: DiffLine, side: SourceSide, extends: Bool) {

        guard side == .left ? line.oldNumber != nil : line.newNumber != nil else {
            return
        }

        if !extends || self.selectionStart == nil || self.selectedSide != side {
            self.selectionStart = line.id
        }

        self.selectionEnd = line.id
        self.selectedSide = side

    }

    func isSelected(_ line: DiffLine, side: SourceSide) -> Bool {

        guard side == self.selectedSide,
              let start = self.selectionStart,
              let end = self.selectionEnd else {
            return false
        }

        return (min(start, end)...max(start, end)).contains(line.id)

    }

    func draft(file: DiffFile, comparison: String) -> AnnotationDraft? {

        guard let start = self.selectionStart, let end = self.selectionEnd else {
            return nil
        }

        let selected = file.lines.filter { (min(start, end)...max(start, end)).contains($0.id) }
        let numbers = selected.compactMap { self.selectedSide == .left ? $0.oldNumber : $0.newNumber }
        let snippets = selected.compactMap { self.selectedSide == .left ? $0.left : $0.right }

        guard let first = numbers.first, let last = numbers.last else {
            return nil
        }

        return AnnotationDraft(
            file: file,
            side: self.selectedSide,
            startLine: first,
            endLine: last,
            snippet: snippets.joined(separator: "\n"),
            source: "mock/\(comparison)/\(self.selectedSide.rawValue.lowercased())/v1"
        )

    }

    // MARK: - Change Navigation

    func changeStarts(_ file: DiffFile) -> [Int] {

        file.lines.indices.compactMap { index in

            guard file.lines[index].isChanged else {
                return nil
            }

            if index == 0 || !file.lines[index - 1].isChanged {
                return file.lines[index].id
            }

            return nil

        }

    }

    func navigate(_ direction: Int, file: DiffFile) {

        let changes = changeStarts(file)

        guard !changes.isEmpty else {
            return
        }

        self.selectedChangeIndex = (self.selectedChangeIndex + direction + changes.count) % changes.count
        self.scrollTarget = changes[self.selectedChangeIndex]

    }

    func findNext(in file: DiffFile) {

        let matches = file.lines.filter {
            ($0.left ?? "").localizedCaseInsensitiveContains(self.search) || ($0.right ?? "").localizedCaseInsensitiveContains(self.search)
        }

        guard !self.search.isEmpty, !matches.isEmpty else {
            return
        }

        self.scrollTarget = matches.first(where: { $0.id > (self.scrollTarget ?? -1) })?.id ?? matches.first?.id

    }

    func visibleLines(_ file: DiffFile, preferences: EditorPreferences) -> [DiffLine] {

        file.lines.filter { line in

            if preferences.ignoreComments && (line.left ?? line.right ?? "").trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                return false
            }

            if preferences.collapseUnchanged && !line.isChanged {

                return file.lines.contains { other in
                    other.isChanged && abs(other.id - line.id) <= preferences.contextLines
                }

            }

            return true

        }

    }

    func visibleRegions(_ file: DiffFile, preferences: EditorPreferences) -> [DiffRegion] {

        let lines = visibleLines(file, preferences: preferences)
        var regions: [DiffRegion] = []
        var currentLines: [DiffLine] = []

        for line in lines {

            if let first = currentLines.first, first.status != line.status {

                regions.append(DiffRegion(id: first.id, lines: currentLines, isChanged: first.isChanged))
                currentLines = []

            }

            currentLines.append(line)

        }

        if let first = currentLines.first {
            regions.append(DiffRegion(id: first.id, lines: currentLines, isChanged: first.isChanged))
        }

        return regions

    }

}
