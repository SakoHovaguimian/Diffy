import SwiftUI
import AppKit

struct TextDiffScreen: View {

    let file: DiffFile
    let presentation: TextDiffPresentation?
    private let annotate: ((AnnotationDraft) -> Void)?
    private let navigateToLine: ((String) -> Void)?
    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject private var viewModel: TextDiffViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @State private var paneDragStartRatio: Double?

    private var gutterWidth: CGFloat {
        self.contentSize.scaled(44)
    }

    private var usesSingleSourceLayout: Bool {
        self.settings.editor.unified || self.comparisonFile.hasNoOriginalSource
    }

    private var allowsEditing: Bool {
        !self.workspace.runtime.isLive && self.presentation == nil
    }

    private var pendingScrollLine: Int? {

        guard self.presentation == nil else { return nil }
        return self.workspace.runtime.isLive ? self.workspace.repositoryViewModel.comparison.scrollTarget : self.workspace.pendingScrollLine

    }

    private var comparisonFile: DiffFile {
        self.allowsEditing ? self.viewModel.displayedFile(self.file) : self.file
    }

    init(
        file: DiffFile,
        workspace: WorkspaceViewModel,
        viewModel: TextDiffViewModel,
        presentation: TextDiffPresentation? = nil,
        annotate: ((AnnotationDraft) -> Void)? = nil,
        navigateToLine: ((String) -> Void)? = nil
    ) {

        self.file = file
        self.workspace = workspace
        self.viewModel = viewModel
        self.presentation = presentation
        self.annotate = annotate
        self.navigateToLine = navigateToLine

    }

    var body: some View {

        VStack(spacing: 0) {

            if self.presentation == nil {
                fileHeader()
            }

            DiffToolbar(viewModel: self.viewModel, file: self.file) {
                createAnnotation()
            }

            if self.viewModel.showsSearch, !self.viewModel.isEditing {
                searchBar()
            }

            sourceHeaders()

            if self.settings.editor.collapseUnchanged, !self.viewModel.isEditing {

                Button("Showing Changed Regions · Show Whole File") {
                    self.settings.editor.collapseUnchanged = false
                }
                .font(self.contentSize.font(size: 10))
                .buttonStyle(.plain)
                .foregroundStyle(self.theme.secondaryText)
                .padding(self.contentSize.scaled(10))

            }

            if self.viewModel.isEditing {
                inlineEditableCanvas()
            } else if self.presentation != nil {
                embeddedCodeCanvas()
            } else {
                codeCanvas()

            }

            comparisonFooter()

        }
        .background(self.theme.background)
        .onAppear { self.viewModel.prepare(file: self.file, allowsEditing: self.allowsEditing) }
        .onChange(of: self.file) { _, file in
            self.viewModel.prepare(file: file, allowsEditing: self.allowsEditing)
        }

    }

    // MARK: - File Context

    private func fileHeader() -> some View {

        HStack(spacing: self.contentSize.scaled(8)) {

            DiffFileIcon(file: self.comparisonFile, size: 14)

            Text(self.comparisonFile.path)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: self.contentSize.scaled(8))
            Text("~\(self.comparisonFile.changedLines)").foregroundStyle(self.theme.changed)
            Text("+\(self.comparisonFile.additions)").foregroundStyle(self.theme.added)
            Text("−\(self.comparisonFile.deletions)").foregroundStyle(self.theme.removed)

        }
        .font(self.contentSize.font(size: 11, weight: .medium))
        .padding(.horizontal, self.contentSize.scaled(18))
        .frame(height: self.contentSize.scaled(48))
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: self.contentSize.scaled(1)) }

    }

    private func sourceHeaders() -> some View {

        GeometryReader { geometry in

            let contentWidth = geometry.size.width - (self.usesSingleSourceLayout ? 0 : self.gutterWidth)

            HStack(spacing: 0) {

                if self.comparisonFile.hasNoOriginalSource {

                    sourceLabel(self.viewModel.isEditing ? "Editing New File" : "New File", detail: rightLabel(), dot: self.theme.added)
                        .frame(width: geometry.size.width)

                } else {

                    sourceLabel(
                        leftSourceTitle(),
                        detail: leftSourceDetail(),
                        dot: self.viewModel.isEditing && self.settings.editor.unified ? self.theme.added : self.theme.removed
                    )
                        .frame(width: self.settings.editor.unified ? geometry.size.width : contentWidth * self.viewModel.paneRatio)

                    if !self.settings.editor.unified {

                        self.theme.background.frame(width: self.gutterWidth)
                        sourceLabel(self.viewModel.isEditing ? "Editing Updated Source" : "Updated", detail: rightLabel(), dot: self.theme.added)
                            .frame(width: contentWidth * (1 - self.viewModel.paneRatio))

                    }

                }

            }

        }
        .frame(height: self.contentSize.scaled(40))
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: self.contentSize.scaled(1)) }

    }

    private func sourceLabel(_ title: String, detail: String, dot: Color) -> some View {

        HStack(spacing: self.contentSize.scaled(7)) {

            Circle().fill(dot.opacity(0.7)).frame(width: self.contentSize.scaled(5), height: self.contentSize.scaled(5))
            Text(title).fontWeight(.medium)
            Spacer()
            Text(detail).foregroundStyle(self.theme.secondaryText).lineLimit(1)

        }
        .font(self.contentSize.font(size: 10))
        .padding(.horizontal, self.contentSize.scaled(16))
        .frame(maxWidth: .infinity)

    }

    private func leftLabel() -> String {

        if let presentation { return presentation.selection.left.displayLabel }

        if self.workspace.runtime.isLive {
            return self.workspace.repositoryViewModel.comparison.selection.left.displayLabel
        }

        if [.branches, .commits, .history].contains(self.workspace.mode) {
            return self.workspace.comparisonLeft
        }

        return "HEAD · a7e2c91"

    }

    private func leftSourceTitle() -> String {

        if self.settings.editor.unified {
            return self.viewModel.isEditing ? "Editing Updated Source" : "Unified Comparison"
        }

        return "Original"

    }

    private func leftSourceDetail() -> String {
        self.viewModel.isEditing && self.settings.editor.unified ? rightLabel() : leftLabel()
    }

    private func rightLabel() -> String {

        if let presentation { return presentation.selection.right.displayLabel }

        if self.workspace.runtime.isLive {
            return self.workspace.repositoryViewModel.comparison.selection.right.displayLabel
        }

        if [.branches, .commits, .history].contains(self.workspace.mode) {
            return self.workspace.comparisonRight
        }

        return self.workspace.mode == .staged ? "Index" : "Working Tree"

    }

    // MARK: - Synchronized Canvas

    private func inlineEditableCanvas() -> some View {

        GeometryReader { geometry in

            let contentWidth = geometry.size.width - (self.usesSingleSourceLayout ? 0 : self.gutterWidth)

            ZStack(alignment: .bottom) {

                HStack(spacing: 0) {

                    if !self.usesSingleSourceLayout {

                        originalEditingPane(width: contentWidth * self.viewModel.paneRatio)

                        self.theme.background
                            .frame(width: self.gutterWidth)
                            .overlay(alignment: .leading) { self.theme.border.frame(width: self.contentSize.scaled(1)) }
                            .overlay(alignment: .trailing) { self.theme.border.frame(width: self.contentSize.scaled(1)) }
                            .contentShape(Rectangle())
                            .gesture(paneResizeGesture(contentWidth: contentWidth))
                            .help("Drag To Resize Comparison Panes")

                    }

                    editableCodePane()
                        .frame(width: self.usesSingleSourceLayout ? geometry.size.width : contentWidth * (1 - self.viewModel.paneRatio))

                }

                applyChangesButton()

            }

        }

    }

    private func originalEditingPane(width: CGFloat) -> some View {

        ScrollViewReader { proxy in

            ScrollView([.vertical, .horizontal]) {

                LazyVStack(spacing: 0) {

                    ForEach(self.comparisonFile.lines) { line in
                        codeLine(line, side: .left, paneWidth: width)
                            .frame(width: width)
                            .allowsHitTesting(false)
                            .id(line.id)
                    }

                }
                .frame(width: width, alignment: .topLeading)
                .padding(.vertical, self.contentSize.scaled(12))

            }
            .onAppear {

                if let target = editingLineID() {
                    proxy.scrollTo(target, anchor: .center)
                }

            }

        }

    }

    private func editingLineID() -> Int? {

        guard let editingLineNumber = self.viewModel.editingLineNumber else {
            return nil
        }

        return self.comparisonFile.lines.first { $0.newNumber == editingLineNumber }?.id

    }

    private func editableCodePane() -> some View {

        LiveDiffEditor(
            text: Binding(
                get: { self.viewModel.draftText },
                set: { self.viewModel.updateDraft($0, file: self.file) }
            ),
            lineStatuses: self.viewModel.updatedLineStatuses(),
            lineComparisons: self.viewModel.updatedLineComparisons(),
            focusLine: self.viewModel.editingLineNumber
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

    private func applyChangesButton() -> some View {

        Button {
            self.viewModel.applyChanges()
        } label: {
            Label("Apply Changes", systemImage: "checkmark.circle.fill")
                .font(self.contentSize.font(size: 14, weight: .semibold))
                .frame(minWidth: self.contentSize.scaled(190))
                .padding(.horizontal, self.contentSize.scaled(18))
                .padding(.vertical, self.contentSize.scaled(5))
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .keyboardShortcut(.return, modifiers: .command)
        .help("Apply This Draft · ⌘Return")
        .shadow(
            color: Color.black.opacity(0.2),
            radius: self.contentSize.scaled(12),
            y: self.contentSize.scaled(4)
        )
        .padding(.bottom, self.contentSize.scaled(24))

    }

    @ViewBuilder
    private func codeCanvas() -> some View {

        let regions = self.viewModel.visibleRegions(self.comparisonFile, preferences: self.settings.editor)

        if regions.isEmpty {

            DiffyEmptyState(
                symbol: "checkmark.circle",
                title: "No Visible Differences",
                message: "No lines match the current display options. Choose File to show the entire source."
            )

        } else {

            GeometryReader { geometry in

                let width = canvasWidth(available: geometry.size.width)

                ScrollViewReader { proxy in

                    ScrollView([.vertical, .horizontal]) {

                        LazyVStack(spacing: 0) {

                            ForEach(regions) { region in
                                diffRegion(region, width: width)
                            }

                        }
                        .frame(width: width, alignment: .topLeading)
                        .padding(.vertical, self.contentSize.scaled(12))

                    }
                    .onAppear {

                        if let target = self.pendingScrollLine {

                            self.settings.editor.collapseUnchanged = false
                            proxy.scrollTo(target, anchor: .center)

                        }

                    }
                    .onChange(of: self.viewModel.scrollTarget) { _, target in

                        if let target {

                            if self.comparisonFile.lines.first(where: { $0.id == target })?.isChanged == false {
                                self.settings.editor.collapseUnchanged = false
                            }

                            proxy.scrollTo(target, anchor: .center)

                        }

                    }
                    .onChange(of: self.pendingScrollLine) { _, target in

                        if let target {

                            self.settings.editor.collapseUnchanged = false
                            proxy.scrollTo(target, anchor: .center)

                        }

                    }

                }

            }

        }

    }

    // MARK: - Continuous Review Canvas

    private func embeddedCodeCanvas() -> some View {

        let regions = self.viewModel.visibleRegions(self.comparisonFile, preferences: self.settings.editor, limit: self.viewModel.reviewLineLimit)
        let totalLines = self.viewModel.visibleLines(self.comparisonFile, preferences: self.settings.editor).count

        return GeometryReader { geometry in

            let width = canvasWidth(available: geometry.size.width)

            ScrollView(.horizontal) {

                VStack(spacing: 0) {

                    ForEach(regions) { region in
                        diffRegion(region, width: width)
                    }

                    if totalLines > self.viewModel.reviewLineLimit {

                        Button("Show More Lines (\(totalLines - self.viewModel.reviewLineLimit) Remaining)") {
                            self.viewModel.reviewLineLimit += 400
                        }
                        .padding(self.contentSize.scaled(14))

                    } else if regions.isEmpty {

                Text("No Visible Text Changes · Choose File To Show The Source")
                            .font(self.contentSize.font(size: 11))
                            .foregroundStyle(self.theme.secondaryText)
                            .padding(self.contentSize.scaled(24))

                    }

                }
                .frame(width: width)
                .padding(.vertical, self.contentSize.scaled(12))
                .fixedSize(horizontal: false, vertical: true)
                .background {

                    GeometryReader { content in
                        Color.clear.preference(key: DiffCanvasHeightPreference.self, value: content.size.height)
                    }

                }

            }

        }
        .frame(height: self.viewModel.embeddedCanvasHeight)
        .onPreferenceChange(DiffCanvasHeightPreference.self) { [viewModel = self.viewModel] height in

            Task { @MainActor in

                if abs(viewModel.embeddedCanvasHeight - height) > 1 {
                    viewModel.embeddedCanvasHeight = height
                }

            }

        }
        .onChange(of: self.viewModel.scrollTarget) { _, target in
            revealReviewLine(target)
        }
        .onChange(of: self.viewModel.embeddedCanvasHeight) { _, _ in
            scrollToReviewLine(self.viewModel.scrollTarget)
        }

    }

    private func revealReviewLine(_ target: Int?) {

        guard let target else { return }
        let visible = self.viewModel.visibleLines(self.comparisonFile, preferences: self.settings.editor)

        if !visible.contains(where: { $0.id == target }) {
            self.settings.editor.collapseUnchanged = false
        }

        let lines = self.viewModel.visibleLines(self.comparisonFile, preferences: self.settings.editor)

        if let index = lines.firstIndex(where: { $0.id == target }) {
            self.viewModel.reviewLineLimit = max(self.viewModel.reviewLineLimit, index + 100)
        }

        scrollToReviewLine(target)

    }

    private func scrollToReviewLine(_ target: Int?) {

        guard let target, let presentation else { return }
        self.navigateToLine?(presentation.lineAnchor(fileID: self.file.id, lineID: target))

    }

    private func diffRegion(_ region: DiffRegion, width: CGFloat) -> some View {

        VStack(spacing: 0) {

            ForEach(region.lines) { line in
                codeRow(line, width: width)
                    .id(self.presentation.map { AnyHashable($0.lineAnchor(fileID: self.file.id, lineID: line.id)) } ?? AnyHashable(line.id))
            }

        }
        .overlay {

            if region.isChanged && !self.usesSingleSourceLayout {

                DiffRegionDecoration(
                    region: region,
                    paneRatio: self.viewModel.paneRatio,
                    gutterWidth: self.gutterWidth,
                    lineHeight: self.contentSize.scaled(self.settings.editor.lineHeight),
                    showsTrailingLines: self.settings.diffVisualization.showsTrailingLines,
                    framesCurrentRegion: self.settings.diffVisualization.framesCurrentRegion
                )

            }

        }

    }

    @ViewBuilder
    private func codeRow(_ line: DiffLine, width: CGFloat) -> some View {

        let contentWidth = width - self.gutterWidth

        if self.usesSingleSourceLayout {

            VStack(spacing: 0) {

                if line.isChanged, line.left != nil {
                    codeLine(line, side: .left, paneWidth: width).frame(width: width)
                }

                if line.right != nil {
                    codeLine(line, side: .right, paneWidth: width).frame(width: width)
                }

            }

        } else {

            HStack(alignment: .top, spacing: 0) {

                codeLine(line, side: .left, paneWidth: contentWidth * self.viewModel.paneRatio)
                    .frame(width: contentWidth * self.viewModel.paneRatio)
                    .clipped()

                self.theme.background
                    .frame(width: self.gutterWidth)
                    .overlay(alignment: .leading) { self.theme.border.frame(width: self.contentSize.scaled(1)) }
                    .overlay(alignment: .trailing) { self.theme.border.frame(width: self.contentSize.scaled(1)) }
                    .contentShape(Rectangle())
                    .gesture(paneResizeGesture(contentWidth: contentWidth))
                    .help("Drag To Resize Comparison Panes")

                codeLine(line, side: .right, paneWidth: contentWidth * (1 - self.viewModel.paneRatio))
                    .frame(width: contentWidth * (1 - self.viewModel.paneRatio))
                    .clipped()

            }
            .fixedSize(horizontal: false, vertical: true)

        }

    }

    private func paneResizeGesture(contentWidth: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0)
            .onChanged { value in

                if self.paneDragStartRatio == nil {
                    self.paneDragStartRatio = self.viewModel.paneRatio
                }

                let startingRatio = self.paneDragStartRatio ?? self.viewModel.paneRatio
                self.viewModel.paneRatio = min(0.7, max(0.3, startingRatio + value.translation.width / contentWidth))

            }
            .onEnded { _ in
                self.paneDragStartRatio = nil
            }

    }

    private func codeLine(_ line: DiffLine, side: SourceSide, paneWidth: CGFloat) -> some View {

        CodeLineView(
            source: side == .left ? line.left : line.right,
            oppositeSource: side == .left ? line.right : line.left,
            number: side == .left ? line.oldNumber : line.newNumber,
            status: line.status,
            side: side,
            selected: self.viewModel.isSelected(line, side: side),
            annotated: hasAnnotation(line, side: side),
            emphasis: line.emphasis,
            paneWidth: paneWidth,
            action: {
                self.viewModel.select(line, side: side, extends: NSEvent.modifierFlags.contains(.shift))
            },
            edit: editAction(for: line, side: side),
            annotate: {

                self.viewModel.select(line, side: side, extends: false)
                createAnnotation()

            }
        )

    }

    private func editAction(for line: DiffLine, side: SourceSide) -> (() -> Void)? {

        guard side == .right, self.allowsEditing else {
            return nil
        }

        let lineNumber = line.newNumber ?? line.oldNumber ?? 1

        return {
            self.viewModel.beginEditing(file: self.file, lineNumber: lineNumber)
        }

    }

    private func canvasWidth(available: CGFloat) -> CGFloat {

        if self.settings.editor.wrapLines {
            return available
        }

        let maximum = self.comparisonFile.lines.map { max($0.left?.count ?? 0, $0.right?.count ?? 0) }.max() ?? 60
        let sourceWidth = CGFloat(maximum) * self.contentSize.scaled(self.settings.editor.fontSize) * 0.61 + self.contentSize.scaled(86)

        return max(available, sourceWidth * (self.usesSingleSourceLayout ? 1 : 2) + (self.usesSingleSourceLayout ? 0 : self.gutterWidth))

    }

    private func hasAnnotation(_ line: DiffLine, side: SourceSide) -> Bool {

        guard let number = side == .left ? line.oldNumber : line.newNumber else {
            return false
        }

        return self.review.annotations.contains {
            $0.projectID == self.workspace.project.id && ($0.filePath == self.comparisonFile.path || $0.filePath == self.comparisonFile.originalPath) && $0.side == side && ($0.startLine...$0.endLine).contains(number)
        }

    }

    private func createAnnotation() {
        let comparison = self.presentation?.selection.title ?? self.workspace.comparisonTitle
        guard var draft = self.viewModel.draft(
            file: self.comparisonFile,
            comparison: comparison,
            sourcePrefix: self.workspace.runtime.isLive ? "git/\(self.workspace.project.id)" : "mock"
        ) else { return }
        draft.comparisonMode = self.presentation?.mode ?? self.workspace.mode

        if let annotate {
            annotate(draft)
        } else {
            self.workspace.annotationDraft = draft
        }

    }

    private func searchBar() -> some View {

        HStack {

            Image(systemName: "magnifyingglass")
            TextField("Find In Comparison", text: self.$viewModel.search)
                .textFieldStyle(.plain)
                .onSubmit { self.viewModel.findNext(in: self.comparisonFile) }
            Button("Next") { self.viewModel.findNext(in: self.comparisonFile) }
            DiffyIconButton(symbol: "xmark", label: "Close Search") { self.viewModel.showsSearch = false }

        }
        .font(self.contentSize.font(size: 11))
        .padding(.horizontal, self.contentSize.scaled(14))
        .padding(.vertical, self.contentSize.scaled(7))
        .background(self.theme.surface)

    }

    private func comparisonFooter() -> some View {

        HStack {

            Text(self.comparisonFile.originalPath.map { "Previously: \($0)" } ?? "\(self.viewModel.changeStarts(self.comparisonFile).count) Change Regions")
            Spacer()
            Text(layoutDescription())
            Text("\(Int(self.settings.editor.fontSize)) pt")

        }
        .font(self.contentSize.font(size: 9))
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, self.contentSize.scaled(14))
        .frame(height: self.contentSize.scaled(30))
        .background(self.theme.surface)

    }

    private func layoutDescription() -> String {

        if self.viewModel.isEditing {
            return "Editable Draft · In Memory"
        }

        if self.comparisonFile.hasNoOriginalSource {
            return "New File"
        }

        return self.settings.editor.unified ? "Unified" : "Synchronized Scrolling"

    }

}

#Preview {

    TextDiffScreen(
        file: MockPreviewFixtures.textFile,
        workspace: mockResolve(WorkspaceViewModel.self),
        viewModel: mockResolve(TextDiffViewModel.self)
    )
    .frame(width: 950, height: 650)
    .withMockPreviews()

}

#Preview("New File") {

    TextDiffScreen(
        file: MockPreviewFixtures.addedTextFile,
        workspace: mockResolve(WorkspaceViewModel.self),
        viewModel: mockResolve(TextDiffViewModel.self)
    )
    .frame(width: 950, height: 650)
    .withMockPreviews()

}
