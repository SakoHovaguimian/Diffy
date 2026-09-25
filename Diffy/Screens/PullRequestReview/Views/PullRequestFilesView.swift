import SwiftUI

struct PullRequestFilesView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var workspace: WorkspaceViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        GeometryReader { geometry in

            HStack(spacing: 0) {

                PullRequestFileNavigator(viewModel: self.viewModel, navigator: self.viewModel.fileNavigator)
                    .frame(width: min(self.viewModel.navigatorWidth, navigatorMaximumWidth(in: geometry.size.width)))
                HorizontalResizeHandle(
                    label: "Drag To Resize Changed Files",
                    resizeGesture: navigatorResizeGesture(availableWidth: geometry.size.width)
                )
                selectedFileContent()

            }

        }

    }

    private func navigatorMaximumWidth(in availableWidth: CGFloat) -> CGFloat {
        min(360, max(190, availableWidth - 400))
    }

    private func navigatorResizeGesture(availableWidth: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                self.viewModel.resizeNavigator(by: value.translation.width, maximumWidth: navigatorMaximumWidth(in: availableWidth))
            }
            .onEnded { _ in
                self.viewModel.finishResizingNavigator()
            }

    }

    private func selectedFileContent() -> some View {

        VStack(spacing: 0) {

            if let file = self.viewModel.selectedFile {
                fileHeader(file)
                fileContent(file)
            } else {
                DiffyEmptyState(symbol: "doc", title: "No Changed Files", message: "Files returned by GitHub will appear here.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        }
        .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)

    }

    private func fileHeader(_ file: PullRequestReviewFile) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 12) {

                DiffyPathIcon(path: file.filename)
                Text(file.filename).font(.system(size: 12, weight: .semibold, design: .monospaced)).textSelection(.enabled)
                Spacer()
                Toggle("Viewed", isOn: Binding(
                    get: { self.viewModel.viewedPaths.contains(file.id) },
                    set: { if $0 { self.viewModel.viewedPaths.insert(file.id) } else { self.viewModel.viewedPaths.remove(file.id) } }
                ))
                .toggleStyle(.checkbox)

            }
            if let previous = file.previousFilename {
                Text("Renamed From \(previous)").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            }
            ViewThatFits(in: .horizontal) {

                HStack(spacing: 12) {

                    fileSummary(file)
                    Spacer(minLength: 12)
                    fileControls()

                }

                VStack(alignment: .leading, spacing: 10) {

                    fileSummary(file)
                    fileControls()

                }

            }
            .font(.system(size: 11, design: .monospaced))

        }
        .padding(16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func fileSummary(_ file: PullRequestReviewFile) -> some View {

        HStack(spacing: 8) {

            Text("+\(file.additions)").foregroundStyle(self.theme.added)
            Text("−\(file.deletions)").foregroundStyle(self.theme.removed)
            if let url = file.blobUrl {
                Link("Open File On GitHub", destination: url)
            }

        }
        .fixedSize(horizontal: true, vertical: false)

    }

    private func fileControls() -> some View {

        HStack(spacing: 8) {

            Button { self.viewModel.moveFile(by: -1) } label: { Image(systemName: "chevron.up") }
                .accessibilityLabel("Previous File")
                .help("Previous File")
                .disabled(!self.viewModel.canMoveFile(by: -1))
            Button { self.viewModel.moveFile(by: 1) } label: { Image(systemName: "chevron.down") }
                .accessibilityLabel("Next File")
                .help("Next File")
                .disabled(!self.viewModel.canMoveFile(by: 1))

        }
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)

    }

    private func fileContent(_ file: PullRequestReviewFile) -> some View {

        VStack(spacing: 0) {

            if file.patch == nil || !file.hasCompletePatch {
                DiffyStatusBanner(message: file.patch == nil
                    ? "GitHub did not provide a text patch for this file (binary, empty, or too large). Open GitHub to inspect it."
                    : "GitHub provided a partial patch. Open GitHub to inspect the complete file.")
                    .padding(16)
            }
            if let comparisonFile = self.viewModel.selectedComparisonFile, file.patch != nil {
                TextDiffScreen(
                    file: comparisonFile,
                    workspace: self.workspace,
                    viewModel: self.viewModel.textDiff,
                    reviewContext: reviewContext(for: file)
                )
            } else {
                PullRequestFileDiscussion(viewModel: self.viewModel, drafts: [], comments: self.viewModel.unanchoredFileComments)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

        }
        .id(file.id)

    }

    private func reviewContext(for file: PullRequestReviewFile) -> TextDiffReviewContext {

        let summary = self.viewModel.details?.summary
        let annotations = self.viewModel.matchingAnnotations(in: self.review.annotations)

        return TextDiffReviewContext(
            leftLabel: summary.map { String($0.baseSHA.prefix(7)) } ?? "Base",
            rightLabel: summary.map { String($0.headSHA.prefix(7)) } ?? "Head",
            layout: self.$viewModel.isUnified,
            visibleDiscussionLineIDs: self.viewModel.discussionLineIDs,
            canComment: self.viewModel.canReview,
            comment: { line, side in

                if line.status == .identical, let number = line.newNumber {
                    self.viewModel.beginComment(line: number, side: "RIGHT")
                    return
                }

                guard let number = side == .left ? line.oldNumber : line.newNumber else { return }
                self.viewModel.beginComment(line: number, side: side.rawValue.uppercased())

            },
            note: { line, side in

                guard let number = side == .left ? line.oldNumber : line.newNumber else { return }
                let snippet = side == .left ? line.left ?? "" : line.right ?? ""
                self.viewModel.beginNote(line: number, side: side.rawValue.uppercased(), snippet: snippet)

            },
            hasAnnotation: { line, side in

                guard let number = side == .left ? line.oldNumber : line.newNumber else { return false }
                let path = side == .left ? file.previousFilename ?? file.filename : file.filename
                return annotations.contains { $0.filePath == path && $0.side == side && ($0.startLine...$0.endLine).contains(number) }

            },
            lineDiscussion: { line in

                AnyView(PullRequestFileDiscussion(
                    viewModel: self.viewModel,
                    drafts: self.viewModel.drafts(at: line),
                    comments: self.viewModel.comments(at: line)
                ))

            },
            fileDiscussion: {

                AnyView(PullRequestFileDiscussion(
                    viewModel: self.viewModel,
                    drafts: [],
                    comments: self.viewModel.unanchoredFileComments
                ))

            }
        )

    }

}
