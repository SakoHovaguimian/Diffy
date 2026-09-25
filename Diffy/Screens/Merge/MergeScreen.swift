import SwiftUI

struct MergeScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @StateObject private var viewModel: MergeViewModel
    @Environment(\.diffyTheme) private var theme

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

                    sourcePane(.base, detail: "Shared starting point", source: self.viewModel.conflict.base, color: self.theme.secondaryText)
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
                Text("\(self.viewModel.resolvedCount) of \(self.viewModel.conflicts.count) resolved")

            }
            .font(.system(size: 10))
            .foregroundStyle(self.theme.secondaryText)
            .padding(14)

        }
        .background(self.theme.background)
        .onAppear { revealPendingConflict() }
        .onChange(of: self.workspace.pendingMergeConflict) { _, _ in revealPendingConflict() }

    }

    private func header() -> some View {

        HStack(spacing: 12) {

            Image(systemName: "arrow.triangle.merge").foregroundStyle(self.theme.modified)
            VStack(alignment: .leading, spacing: 4) {

                Text("Bring both sides together.").font(.system(size: 17, weight: .semibold))
                Text("NavigationService.swift · mock three-way merge").font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)

            }
            Spacer()
            DiffyBadge(title: "\(self.viewModel.conflicts.count - self.viewModel.resolvedCount) UNRESOLVED", color: self.theme.modified)

        }
        .padding(20)
        .background(self.theme.surface)

    }

    private func conflictNavigation() -> some View {

        HStack(spacing: 8) {

            DiffyIconButton(symbol: "chevron.left", label: "Previous conflict") { self.viewModel.navigate(-1) }
            DiffyIconButton(symbol: "chevron.right", label: "Next conflict") { self.viewModel.navigate(1) }

            Text(self.viewModel.conflict.title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)

            Spacer()

            ForEach(self.viewModel.conflicts) { conflict in

                Button { self.viewModel.selectedIndex = conflict.id } label: {

                    RoundedRectangle(cornerRadius: 3)
                        .fill(self.viewModel.decisions[conflict.id] == nil || self.viewModel.decisions[conflict.id] == .unresolved ? self.theme.modified.opacity(0.4) : self.theme.added)
                        .frame(width: 22, height: 7)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(self.viewModel.selectedIndex == conflict.id ? self.theme.text : .clear))

                }
                .buttonStyle(.plain)
                .help("Conflict \(conflict.id + 1): \(conflict.title)")
                .accessibilityLabel("Conflict \(conflict.id + 1)")

            }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)

    }

    private func sourcePane(_ side: SourceSide, detail: String, source: String, color: Color) -> some View {

        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 5) {

                HStack {

                    Text(side.rawValue).font(.system(size: 12, weight: .semibold)).foregroundStyle(color)
                    Spacer()
                    DiffyIconButton(symbol: "text.bubble", label: "Annotate \(side.rawValue) conflict") {
                        annotate(source, side: side)
                    }

                }
                Text(detail).font(.system(size: 9)).foregroundStyle(self.theme.secondaryText).lineLimit(1)

            }
            .padding(14)

            ScrollView([.horizontal, .vertical]) {

                Text(source)
                    .font(.system(size: 11, design: .monospaced))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

            }

        }
        .frame(minWidth: 125, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.035))

    }

    private func resultPane() -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Label("Result", systemImage: "pencil.line").font(.system(size: 13, weight: .semibold))
                Spacer()
                Button("Annotate") { annotate(self.viewModel.result, side: .result) }
                Button("Undo") { self.viewModel.undo() }.disabled(!self.viewModel.canUndo)
                Button("Reset draft") { self.viewModel.reset() }

            }
            .font(.system(size: 10))

            ViewThatFits(in: .horizontal) {
                decisions(horizontal: true)
                decisions(horizontal: false)
            }

            TextEditor(text: Binding(get: { self.viewModel.result }, set: { self.viewModel.editResult($0) }))
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(self.theme.border))

            HStack {

                Text(self.viewModel.decisions[self.viewModel.conflict.id]?.rawValue ?? "Unresolved")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                Spacer()
                Button("Mark resolved") { self.viewModel.markResolved() }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)

            }

        }
        .padding(18)

    }

    private func decisions(horizontal: Bool) -> some View {

        let layout = horizontal ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 6))

        return layout {

            Button("Accept yours") { self.viewModel.accept(.yours) }
            Button("Accept theirs") { self.viewModel.accept(.theirs) }
            Button("Both: yours → theirs") { self.viewModel.accept(.both) }
            Button("Reject both · keep base") { self.viewModel.accept(.base) }

        }
        .font(.system(size: 10))
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
