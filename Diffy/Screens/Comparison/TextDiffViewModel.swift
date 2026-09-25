import SwiftUI
import Combine

@MainActor
final class TextDiffViewModel: ViewModel {

    let loggerName = "TEXT_DIFF_VIEW_MODEL"
    private let diffBuilder: TextDiffBuilding
    private var preparedFileID: String?
    private var appliedDrafts: [String: TextDiffDraftSnapshot] = [:]
    private var appliedText = ""
    private var appliedLines: [DiffLine] = []
    @Published var selectionStart: Int?
    @Published var selectionEnd: Int?
    @Published var selectedSide: SourceSide = .right
    @Published var selectedChangeIndex = 0
    @Published var scrollTarget: Int?
    @Published var search = ""
    @Published var showsSearch = false
    @Published var paneRatio = 0.5
    @Published private(set) var draftText = ""
    @Published private(set) var draftLines: [DiffLine] = []
    @Published var embeddedCanvasHeight: CGFloat = 120
    @Published var reviewLineLimit = 400
    @Published var isEditing = false
    @Published private(set) var editingLineNumber: Int?

    var hasUnappliedChanges: Bool {
        self.preparedFileID != nil && self.draftText != self.appliedText
    }

    init(diffBuilder: TextDiffBuilding) {
        self.diffBuilder = diffBuilder
    }

    // MARK: - Editable Draft

    func prepare(file: DiffFile, allowsEditing: Bool = true) {

        if !allowsEditing {

            self.preparedFileID = file.id
            self.appliedText = file.updatedSource
            self.appliedLines = file.lines
            self.draftText = file.updatedSource
            self.draftLines = file.lines
            finishEditing()
            return

        }

        guard self.preparedFileID != file.id else {
            return
        }

        let appliedDraft = self.appliedDrafts[file.id] ?? TextDiffDraftSnapshot(
            text: file.updatedSource,
            lines: file.lines
        )

        self.preparedFileID = file.id
        self.appliedText = appliedDraft.text
        self.appliedLines = appliedDraft.lines
        self.draftText = appliedDraft.text
        self.draftLines = appliedDraft.lines
        self.isEditing = false
        self.editingLineNumber = nil
        clearSelection()

    }

    func displayedFile(_ file: DiffFile) -> DiffFile {

        guard self.preparedFileID == file.id else {
            return file
        }

        return file.replacingLines(self.draftLines)

    }

    func updateDraft(_ source: String, file: DiffFile) {

        prepare(file: file)

        self.draftText = source
        self.draftLines = self.diffBuilder.lines(
            original: sourceLines(file.originalSource),
            updated: sourceLines(source)
        )
        clearSelection()

    }

    func beginEditing(file: DiffFile, lineNumber: Int?) {

        prepare(file: file)
        self.isEditing = true
        self.editingLineNumber = lineNumber
        self.showsSearch = false
        clearSelection()

    }

    func finishEditing() {

        self.isEditing = false
        self.editingLineNumber = nil
        clearSelection()

    }

    func applyChanges() {

        guard let preparedFileID = self.preparedFileID else {
            return
        }

        let appliedDraft = TextDiffDraftSnapshot(text: self.draftText, lines: self.draftLines)
        self.appliedDrafts[preparedFileID] = appliedDraft
        self.appliedText = appliedDraft.text
        self.appliedLines = appliedDraft.lines
        finishEditing()

    }

    func discardChanges() {

        self.draftText = self.appliedText
        self.draftLines = self.appliedLines
        finishEditing()

    }

    func resetDraft(file: DiffFile) {

        guard self.preparedFileID == file.id else {
            return
        }

        self.draftText = self.appliedText
        self.draftLines = self.appliedLines
        clearSelection()

    }

    func isDraftModified(file: DiffFile) -> Bool {
        self.preparedFileID == file.id && self.hasUnappliedChanges
    }

    func updatedLineStatuses() -> [FileChangeStatus] {
        self.draftLines.compactMap { $0.right == nil ? nil : $0.status }
    }

    private func sourceLines(_ source: String) -> [String] {
        source.isEmpty ? [] : source.components(separatedBy: "\n")
    }

    private func clearSelection() {

        self.selectionStart = nil
        self.selectionEnd = nil
        self.selectedChangeIndex = 0
        self.scrollTarget = nil

    }

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

    func draft(file: DiffFile, comparison: String, sourcePrefix: String = "mock") -> AnnotationDraft? {

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
            source: "\(sourcePrefix)/\(comparison)/\(self.selectedSide.rawValue.lowercased())/v1",
            comparisonTitle: comparison
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

        if self.scrollTarget == nil {
            self.selectedChangeIndex = direction < 0 ? changes.count - 1 : 0
        } else {
            self.selectedChangeIndex = (self.selectedChangeIndex + direction + changes.count) % changes.count
        }
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

        let changedIDs = file.lines.filter(\.isChanged).map(\.id)
        let context = max(0, preferences.contextLines)
        var nextChange = 0

        return file.lines.filter { line in

            if preferences.ignoreComments && (line.left ?? line.right ?? "").trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                return false
            }

            guard preferences.collapseUnchanged, !line.isChanged else { return true }

            while nextChange < changedIDs.count && changedIDs[nextChange] < line.id - context {
                nextChange += 1
            }

            return nextChange < changedIDs.count && changedIDs[nextChange] <= line.id + context

        }

    }

    func visibleRegions(_ file: DiffFile, preferences: EditorPreferences, limit: Int? = nil) -> [DiffRegion] {

        let visible = visibleLines(file, preferences: preferences)
        let lines = Array(visible.prefix(limit ?? visible.count))
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
