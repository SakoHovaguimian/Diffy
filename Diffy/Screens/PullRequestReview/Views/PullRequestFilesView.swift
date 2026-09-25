import SwiftUI

struct PullRequestFilesView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
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
                    diffControls()

                }

                VStack(alignment: .leading, spacing: 10) {

                    fileSummary(file)
                    diffControls()

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

    private func diffControls() -> some View {

        HStack(spacing: 8) {

            Text("Diff Layout")
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
            Picker("Diff Layout", selection: self.$viewModel.isUnified) {

                Text("Unified").tag(true)
                Text("Split").tag(false)

            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 135)
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

        GeometryReader { geometry in

            ScrollView([.horizontal, .vertical]) {

                patchContent(file)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, alignment: .topLeading)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .id(file.id)

        }

    }

    private func patchContent(_ file: PullRequestReviewFile) -> some View {

        VStack(alignment: .leading, spacing: 0) {

            if file.patch == nil || !file.hasCompletePatch {

                DiffyStatusBanner(message: file.patch == nil
                    ? "GitHub did not provide a text patch for this file (binary, empty, or too large). Open GitHub to inspect it."
                    : "GitHub provided a partial patch. Open GitHub to inspect the complete file.")
                    .padding(16)

            }
            LazyVStack(alignment: .leading, spacing: 0) {

                ForEach(Array(self.viewModel.lines.enumerated()), id: \.element.id) { index, line in

                    if hasGap(before: index) {
                Text("⋯ Unchanged Lines Omitted ⋯")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(self.theme.secondaryText)
                            .padding(10)
                    }
                    PullRequestPatchRow(line: line, unified: self.viewModel.isUnified, canComment: self.viewModel.canReview, comment: self.viewModel.beginComment)
                    PullRequestFileDiscussion(viewModel: self.viewModel, drafts: self.viewModel.drafts(at: line), comments: self.viewModel.comments(at: line))

                }

            }
            .textSelection(.enabled)
            PullRequestFileDiscussion(viewModel: self.viewModel, drafts: [], comments: self.viewModel.unanchoredFileComments)

        }
        .frame(maxWidth: .infinity, alignment: .topLeading)

    }

    private func hasGap(before index: Int) -> Bool {

        guard index > 0 else { return false }
        let previous = self.viewModel.lines[index - 1]
        let current = self.viewModel.lines[index]
        if let old = current.oldNumber, let last = previous.oldNumber, old > last + 1 { return true }
        if let new = current.newNumber, let last = previous.newNumber, new > last + 1 { return true }
        return false

    }

}
