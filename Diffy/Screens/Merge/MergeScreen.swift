import SwiftUI

struct MergeScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @StateObject private var viewModel: MergeViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    init(
        workspace: WorkspaceViewModel,
        viewModel: MergeViewModel
    ) {

        self.workspace = workspace
        self._viewModel = StateObject(wrappedValue: viewModel)

    }

    var body: some View {

        VStack(spacing: 0) {

            header()
            conflictNavigation()

            VSplitView {

                HSplitView {

                    sourcePane(.base, detail: "Shared Starting Point", source: self.viewModel.conflict.base, color: self.theme.secondaryText)
                    sourcePane(.yours, detail: "feature/refine-the-details", source: self.viewModel.conflict.yours, color: self.theme.accent)
                    sourcePane(.theirs, detail: "main", source: self.viewModel.conflict.theirs, color: self.theme.added)

                }
                .frame(minHeight: 140)

                resultPane()
                    .frame(minHeight: 200)

            }

            HStack {

                Text("Temporary result · source fixtures never change")
                Spacer()
                Text("\(self.viewModel.resolvedCount) Of \(self.viewModel.conflicts.count) Resolved")

            }
            .font(self.contentSize.font(size: 10))
            .foregroundStyle(self.theme.secondaryText)
            .padding(self.contentSize.scaled(14))

        }
        .background(self.theme.background)
        .onAppear { revealPendingConflict() }
        .onChange(of: self.workspace.pendingMergeConflict) { _, _ in revealPendingConflict() }

    }

    private func header() -> some View {

        HStack(spacing: self.contentSize.scaled(12)) {

            Image(systemName: "arrow.triangle.merge").foregroundStyle(self.theme.modified)
            VStack(alignment: .leading, spacing: self.contentSize.scaled(4)) {

                Text("Bring Both Sides Together.").font(self.contentSize.font(size: 17, weight: .semibold))
                Text("NavigationService.swift · mock three-way merge").font(self.contentSize.font(size: 10)).foregroundStyle(self.theme.secondaryText)

            }
            Spacer()
            DiffyBadge(title: "\(self.viewModel.conflicts.count - self.viewModel.resolvedCount) UNRESOLVED", color: self.theme.modified)

        }
        .padding(self.contentSize.scaled(20))
        .background(self.theme.surface)

    }

    private func conflictNavigation() -> some View {

        HStack(spacing: self.contentSize.scaled(8)) {

            DiffyIconButton(symbol: "chevron.left", label: "Previous Conflict") { self.viewModel.navigate(-1) }
            DiffyIconButton(symbol: "chevron.right", label: "Next Conflict") { self.viewModel.navigate(1) }

            Text(self.viewModel.conflict.title)
                .font(self.contentSize.font(size: 11, weight: .medium))
                .lineLimit(1)

            Spacer()

            ForEach(self.viewModel.conflicts) { conflict in

                Button { self.viewModel.selectedIndex = conflict.id } label: {

                    RoundedRectangle(cornerRadius: self.contentSize.scaled(3))
                        .fill(self.viewModel.decisions[conflict.id] == nil || self.viewModel.decisions[conflict.id] == .unresolved ? self.theme.modified.opacity(0.4) : self.theme.added)
                        .frame(width: self.contentSize.scaled(22), height: self.contentSize.scaled(7))
                        .overlay(RoundedRectangle(cornerRadius: self.contentSize.scaled(3)).stroke(self.viewModel.selectedIndex == conflict.id ? self.theme.text : .clear))

                }
                .buttonStyle(.plain)
                .help("Conflict \(conflict.id + 1): \(conflict.title)")
                .accessibilityLabel("Conflict \(conflict.id + 1)")

            }

        }
        .padding(.horizontal, self.contentSize.scaled(12))
        .padding(.vertical, self.contentSize.scaled(8))

    }

    private func sourcePane(_ side: SourceSide, detail: String, source: String, color: Color) -> some View {

        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: self.contentSize.scaled(5)) {

                HStack {

                    Text(side.rawValue).font(self.contentSize.font(size: 12, weight: .semibold)).foregroundStyle(color)
                    Spacer()
                    DiffyIconButton(symbol: "text.bubble", label: "Annotate \(side.rawValue) Conflict") {
                        annotate(source, side: side)
                    }

                }
                Text(detail).font(self.contentSize.font(size: 9)).foregroundStyle(self.theme.secondaryText).lineLimit(1)

            }
            .padding(self.contentSize.scaled(14))

            ScrollView([.horizontal, .vertical]) {

                Text(source)
                    .font(self.contentSize.font(size: 11, design: .monospaced))
                    .lineSpacing(self.contentSize.scaled(5))
                    .textSelection(.enabled)
                    .padding(self.contentSize.scaled(14))
                    .frame(maxWidth: .infinity, alignment: .topLeading)

            }

        }
        .frame(minWidth: 125, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.035))

    }

    private func resultPane() -> some View {

        VStack(alignment: .leading, spacing: self.contentSize.scaled(12)) {

            HStack {

                Label("Result", systemImage: "pencil.line").font(self.contentSize.font(size: 13, weight: .semibold))
                Spacer()
                Button("Annotate") { annotate(self.viewModel.result, side: .result) }
                Button("Undo") { self.viewModel.undo() }.disabled(!self.viewModel.canUndo)
                Button("Reset Draft") { self.viewModel.reset() }

            }
            .font(self.contentSize.font(size: 10))

            ViewThatFits(in: .horizontal) {

                decisions(horizontal: true)
                decisions(horizontal: false)

            }

            TextEditor(text: Binding(get: { self.viewModel.result }, set: { self.viewModel.editResult($0) }))
                .font(self.contentSize.font(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(self.contentSize.scaled(8))
                .background(self.theme.surface, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(7)))
                .overlay(RoundedRectangle(cornerRadius: self.contentSize.scaled(7)).stroke(self.theme.border))

            HStack {

                Text(self.viewModel.decisions[self.viewModel.conflict.id]?.displayName ?? "Unresolved")
                    .font(self.contentSize.font(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer()
                Button("Mark Resolved") { self.viewModel.markResolved() }
                    .font(self.contentSize.font(size: 11))
                    .buttonStyle(.borderedProminent)

            }

        }
        .padding(self.contentSize.scaled(18))

    }

    private func decisions(horizontal: Bool) -> some View {

        let spacing = self.contentSize.scaled(6)
        let layout = horizontal ? AnyLayout(HStackLayout(spacing: spacing)) : AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))

        return layout {

            Button("Accept Yours") { self.viewModel.accept(.yours) }
            Button("Accept Theirs") { self.viewModel.accept(.theirs) }
            Button("Both: Yours → Theirs") { self.viewModel.accept(.both) }
            Button("Reject Both · Keep Base") { self.viewModel.accept(.base) }

        }
        .font(self.contentSize.font(size: 10))
        .controlSize(.small)

    }

    private func annotate(_ source: String, side: SourceSide) {

        guard let file = self.workspace.project.files.first(where: { $0.status == .conflicted }) else {
            return
        }

        let start = self.viewModel.startLine(for: side)
        let identity = side == .result ? "captured-result-\(UUID().uuidString)" : "v1"

        self.workspace.annotationDraft = AnnotationDraft(
            file: file,
            side: side,
            startLine: start,
            endLine: start + source.components(separatedBy: "\n").count - 1,
            snippet: source,
            source: "mock/merge/conflict-\(self.viewModel.selectedIndex + 1)/\(side.rawValue.lowercased())/\(identity)"
        )

    }

    private func revealPendingConflict() {

        guard let index = self.workspace.pendingMergeConflict,
              self.viewModel.conflicts.indices.contains(index) else {
            return
        }

        self.viewModel.selectedIndex = index

    }

}

#Preview {

    MergeScreen(
        workspace: mockResolveWorkspace(mode: .merge),
        viewModel: mockResolve(MergeViewModel.self)
    )
    .frame(width: 1050, height: 720)
    .withMockPreviews()

}
