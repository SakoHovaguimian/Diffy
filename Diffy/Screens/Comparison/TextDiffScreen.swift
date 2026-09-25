import SwiftUI
import AppKit

struct TextDiffScreen: View {

    let file: DiffFile
    @ObservedObject var workspace: WorkspaceViewModel
    @StateObject private var viewModel: TextDiffViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @State private var paneDragStartRatio: Double?
    private let gutterWidth: CGFloat = 44

    private var usesSingleSourceLayout: Bool {
        self.settings.editor.unified || self.file.hasNoOriginalSource
    }

    init(
        file: DiffFile,
        workspace: WorkspaceViewModel,
        viewModel: TextDiffViewModel
    ) {

        self.file = file
        self.workspace = workspace
        self._viewModel = StateObject(wrappedValue: viewModel)

    }

    var body: some View {

        VStack(spacing: 0) {

            fileHeader()
            DiffToolbar(viewModel: self.viewModel, file: self.file) {
                createAnnotation()
            }

            if self.viewModel.showsSearch {
                searchBar()
            }

            sourceHeaders()

            if self.settings.editor.collapseUnchanged {

                Button("Unchanged regions collapsed · Show all lines") {
                    self.settings.editor.collapseUnchanged = false
                }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundStyle(self.theme.secondaryText)
                .padding(10)

            }

            codeCanvas()
            comparisonFooter()

        }
        .background(self.theme.background)

    }

    // MARK: - File Context

    private func fileHeader() -> some View {

        HStack(spacing: 8) {

            DiffFileIcon(file: self.file, size: 14)

            Text(self.file.path)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)
            Text("~\(self.file.changedLines)").foregroundStyle(self.theme.changed)
            Text("+\(self.file.additions)").foregroundStyle(self.theme.added)
            Text("−\(self.file.deletions)").foregroundStyle(self.theme.removed)

        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func sourceHeaders() -> some View {

        GeometryReader { geometry in

            let contentWidth = geometry.size.width - (self.usesSingleSourceLayout ? 0 : self.gutterWidth)

            HStack(spacing: 0) {

                if self.file.hasNoOriginalSource {

                    sourceLabel("New file", detail: rightLabel(), dot: self.theme.added)
                        .frame(width: geometry.size.width)

                } else {

                    sourceLabel(self.settings.editor.unified ? "Unified comparison" : "Original", detail: leftLabel(), dot: self.theme.removed)
                        .frame(width: self.settings.editor.unified ? geometry.size.width : contentWidth * self.viewModel.paneRatio)

                    if !self.settings.editor.unified {

                        self.theme.background.frame(width: self.gutterWidth)
                        sourceLabel("Updated", detail: rightLabel(), dot: self.theme.added)
                            .frame(width: contentWidth * (1 - self.viewModel.paneRatio))

                    }

                }

            }

        }
        .frame(height: 40)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func sourceLabel(_ title: String, detail: String, dot: Color) -> some View {

        HStack(spacing: 7) {

            Circle().fill(dot.opacity(0.7)).frame(width: 5, height: 5)
            Text(title).fontWeight(.medium)
            Spacer()
            Text(detail).foregroundStyle(self.theme.secondaryText).lineLimit(1)

        }
        .font(.system(size: 10))
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)

    }

    private func leftLabel() -> String {

        if [.branches, .commits, .history].contains(self.workspace.mode) {
            return self.workspace.comparisonLeft
        }

        return "HEAD · a7e2c91"

    }

    private func rightLabel() -> String {

        if [.branches, .commits, .history].contains(self.workspace.mode) {
            return self.workspace.comparisonRight
        }

        return self.workspace.mode == .staged ? "Index" : "Working tree"

    }

    // MARK: - Synchronized Canvas

    private func codeCanvas() -> some View {

        GeometryReader { geometry in

            let width = canvasWidth(available: geometry.size.width)

            ScrollViewReader { proxy in

                ScrollView([.vertical, .horizontal]) {

                    LazyVStack(spacing: 0) {

                        ForEach(self.viewModel.visibleRegions(self.file, preferences: self.settings.editor)) { region in
                            diffRegion(region, width: width)
                        }

                    }
                    .frame(width: width, alignment: .topLeading)
                    .padding(.vertical, 12)

                }
                .onAppear {

                    if let target = self.workspace.pendingScrollLine {
                        proxy.scrollTo(target, anchor: .center)
                    }

                }
                .onChange(of: self.viewModel.scrollTarget) { _, target in

                    if let target {
                        proxy.scrollTo(target, anchor: .center)
                    }

                }
                .onChange(of: self.workspace.pendingScrollLine) { _, target in

                    if let target {

                        self.settings.editor.collapseUnchanged = false
                        proxy.scrollTo(target, anchor: .center)

                    }

                }

            }

        }

    }

    private func diffRegion(_ region: DiffRegion, width: CGFloat) -> some View {

        VStack(spacing: 0) {

            ForEach(region.lines) { line in
                codeRow(line, width: width).id(line.id)
            }

        }
        .overlay {

            if region.isChanged && !self.usesSingleSourceLayout {

                DiffRegionDecoration(
                    region: region,
                    paneRatio: self.viewModel.paneRatio,
                    gutterWidth: self.gutterWidth,
                    lineHeight: self.settings.editor.lineHeight,
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
                    codeLine(line, side: .left).frame(width: width)
                }

                if line.right != nil {
                    codeLine(line, side: .right).frame(width: width)
                }

            }

        } else {

            HStack(alignment: .top, spacing: 0) {

                codeLine(line, side: .left)
                    .frame(width: contentWidth * self.viewModel.paneRatio)
                    .clipped()

                self.theme.background
                    .frame(width: self.gutterWidth)
                    .overlay(alignment: .leading) { self.theme.border.frame(width: 1) }
                    .overlay(alignment: .trailing) { self.theme.border.frame(width: 1) }
                    .contentShape(Rectangle())
                    .gesture(paneResizeGesture(contentWidth: contentWidth))
                    .help("Drag to resize comparison panes")

                codeLine(line, side: .right)
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

    private func codeLine(_ line: DiffLine, side: SourceSide) -> some View {

        CodeLineView(
            source: side == .left ? line.left : line.right,
            number: side == .left ? line.oldNumber : line.newNumber,
            status: line.status,
            side: side,
            selected: self.viewModel.isSelected(line, side: side),
            annotated: hasAnnotation(line, side: side),
            emphasis: line.emphasis,
            action: {
                self.viewModel.select(line, side: side, extends: NSEvent.modifierFlags.contains(.shift))
            },
            annotate: {

                self.viewModel.select(line, side: side, extends: false)
                createAnnotation()

            }
        )

    }

    private func canvasWidth(available: CGFloat) -> CGFloat {

        if self.settings.editor.wrapLines {
            return available
        }

        let maximum = self.file.lines.map { max($0.left?.count ?? 0, $0.right?.count ?? 0) }.max() ?? 60
        let sourceWidth = CGFloat(maximum) * self.settings.editor.fontSize * 0.61 + 86

        return max(available, sourceWidth * (self.usesSingleSourceLayout ? 1 : 2) + (self.usesSingleSourceLayout ? 0 : self.gutterWidth))

    }

    private func hasAnnotation(_ line: DiffLine, side: SourceSide) -> Bool {

        guard let number = side == .left ? line.oldNumber : line.newNumber else {
            return false
        }

        return self.review.annotations.contains {
            $0.projectID == self.workspace.project.id && ($0.filePath == self.file.path || $0.filePath == self.file.originalPath) && $0.side == side && ($0.startLine...$0.endLine).contains(number)
        }

    }

    private func createAnnotation() {
        self.workspace.annotationDraft = self.viewModel.draft(file: self.file, comparison: self.workspace.comparisonTitle)
    }

    private func searchBar() -> some View {

        HStack {

            Image(systemName: "magnifyingglass")
            TextField("Find in comparison", text: self.$viewModel.search)
                .textFieldStyle(.plain)
                .onSubmit { self.viewModel.findNext(in: self.file) }
            Button("Next") { self.viewModel.findNext(in: self.file) }
            DiffyIconButton(symbol: "xmark", label: "Close search") { self.viewModel.showsSearch = false }

        }
        .font(.system(size: 11))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(self.theme.surface)

    }

    private func comparisonFooter() -> some View {

        HStack {

            Text(self.file.originalPath.map { "Previously: \($0)" } ?? "\(self.viewModel.changeStarts(self.file).count) change regions")
            Spacer()
            Text(layoutDescription())
            Text("\(Int(self.settings.editor.fontSize)) pt")

        }
        .font(.system(size: 9))
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, 14)
        .frame(height: 30)
        .background(self.theme.surface)

    }

    private func layoutDescription() -> String {

        if self.file.hasNoOriginalSource {
            return "New file"
        }

        return self.settings.editor.unified ? "Unified" : "Synchronized scrolling"

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

#Preview("New file") {

    TextDiffScreen(
        file: MockPreviewFixtures.addedTextFile,
        workspace: mockResolve(WorkspaceViewModel.self),
        viewModel: mockResolve(TextDiffViewModel.self)
    )
    .frame(width: 950, height: 650)
    .withMockPreviews()

}
