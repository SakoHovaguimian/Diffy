import SwiftUI

struct ReviewScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scope = "All Projects"
    @State private var query = ""
    @State private var onlyOpen = false
    @State private var needsReviewOnly = false
    @State private var showsExport = false
    @State private var exportEverything = true
    @State private var showsDeleteAllConfirmation = false
    @State private var editingAnnotation: CodeAnnotation?
    @State private var collapsedProjectIDs: Set<String> = []
    @State private var deletionProjectID: String?

    private var scopedAnnotations: [CodeAnnotation] {

        guard let selectedProject = self.workspace.selectedProject else {
            return self.scope == "All Projects" ? self.review.annotations : []
        }

        return self.review.annotations.filter { annotation in

            switch self.scope {

            case "Comparison":
                annotation.projectID == selectedProject.id && annotation.comparison == self.workspace.comparisonTitle

            case "Project":
                annotation.projectID == selectedProject.id

            default:
                true

            }

        }

    }

    private var visibleAnnotations: [CodeAnnotation] {

        self.scopedAnnotations.filter {
            (!self.onlyOpen || !$0.isResolved)
                && (!self.needsReviewOnly || $0.needsReview)
                && (self.query.isEmpty
                    || $0.comment.localizedCaseInsensitiveContains(self.query)
                    || $0.filePath.localizedCaseInsensitiveContains(self.query)
                    || $0.projectName.localizedCaseInsensitiveContains(self.query)
                    || $0.comparison.localizedCaseInsensitiveContains(self.query)
                    || ($0.acceptanceCriteria?.localizedCaseInsensitiveContains(self.query) ?? false))
        }

    }

    private var visibleProjectIDs: [String] {

        Array(Set(self.visibleAnnotations.map(\.projectID))).sorted { left, right in
            let order = projectName(left).localizedStandardCompare(projectName(right))
            return order == .orderedSame ? left < right : order == .orderedAscending
        }

    }

    private func projectName(_ projectID: String) -> String {
        self.workspace.projects.first { $0.id == projectID }?.displayName
            ?? self.review.annotations.first { $0.projectID == projectID }?.projectName
            ?? projectID
    }

    var body: some View {

        VStack(spacing: 0) {

            header()

            if let error = self.review.errorMessage {
                DiffyStatusBanner(message: error, isError: true)
                    .padding(10)
            }

            if self.visibleAnnotations.isEmpty {

                DiffyEmptyState(
                    symbol: "text.bubble",
                    title: self.review.annotations.isEmpty ? "Room For Your Thoughts" : "No Matching Notes",
                    message: self.review.annotations.isEmpty
                        ? "Select a line of code, then choose Annotate. Your review comes together here."
                        : "Try another scope, search, or review filter."
                )

            } else {

                ScrollView {

                    LazyVStack(alignment: .leading, spacing: 12) {

                        ForEach(self.visibleProjectIDs, id: \.self) { projectID in
                            projectSection(projectID)
                        }

                    }
                    .padding(14)

                }

            }

            exportFooter()

        }
        .background(self.theme.isDark ? self.theme.surface : self.theme.sidebar)
        .sheet(isPresented: self.$showsExport) {

            ReviewExportScreen(
                annotations: self.exportEverything ? self.review.annotations : self.scopedAnnotations,
                scope: self.exportEverything ? "All Projects · every saved note" : "\(self.workspace.selectedProject?.displayName ?? "Project") · \(self.scope.lowercased())",
                allowsOpenOnly: !self.exportEverything
            )
            .diffyStyle()

        }
        .sheet(item: self.$editingAnnotation) { annotation in
            EditAnnotationScreen(annotation: annotation).diffyStyle()
        }
        .confirmationDialog(
            "Delete All Notes For \(projectName(self.deletionProjectID ?? ""))?",
            isPresented: Binding(
                get: { self.deletionProjectID != nil },
                set: { if !$0 { self.deletionProjectID = nil } }
            )
        ) {

            Button("Delete All Project Notes", role: .destructive) {

                if let projectID = self.deletionProjectID {
                    self.review.removeAll(projectID: projectID)
                }

                self.deletionProjectID = nil

            }

        } message: {
            Text("This removes \(self.review.annotations.filter { $0.projectID == self.deletionProjectID }.count) notes from this project. You can undo the deletion until another note is deleted.")
        }
        .confirmationDialog(
            "Delete All \(self.review.annotations.count) Notes?",
            isPresented: self.$showsDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Notes", role: .destructive) { self.review.removeAll() }
        } message: {
            Text("This removes notes from every project. Undo is available until another note is deleted.")
        }
        .onAppear { checkCurrentSources() }
        .onChange(of: self.workspace.files) { _, _ in checkCurrentSources() }
        .onChange(of: self.workspace.selectedProjectID) { _, _ in checkCurrentSources() }
        .onChange(of: self.workspace.comparisonTitle) { _, _ in checkCurrentSources() }

    }

    private func projectSection(_ projectID: String) -> some View {

        let annotations = self.visibleAnnotations.filter { $0.projectID == projectID }
        let isCollapsed = self.collapsedProjectIDs.contains(projectID)
        let project = self.workspace.projects.first { $0.id == projectID }
        let color = project.flatMap { project in
            self.workspace.bucket(for: project).map { Color(hex: $0.accentHex) }
                ?? project.accentHex.map { Color(hex: $0) }
        } ?? self.theme.secondaryText

        return LazyVStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 0) {

                Button {

                    withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                        if isCollapsed {
                            self.collapsedProjectIDs.remove(projectID)
                        } else {
                            self.collapsedProjectIDs.insert(projectID)
                        }
                    }

                } label: {

                    HStack(spacing: 9) {

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                            .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.22), value: isCollapsed)
                        WorkspaceIdentityIcon(
                            symbol: project?.symbol ?? "folder",
                            customIcon: project?.customIcon,
                            size: 17
                        )
                        .foregroundStyle(color)
                        Text(projectName(projectID).uppercased())
                            .tracking(0.7)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text("\(annotations.count)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(self.theme.secondaryText)

                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(self.theme.isDark ? color : self.theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())

                }
                .buttonStyle(.plain)
                .help(isCollapsed ? "Expand \(projectName(projectID))" : "Collapse \(projectName(projectID))")
                .accessibilityLabel("\(isCollapsed ? "Expand" : "Collapse") \(projectName(projectID))")

                Button {
                    self.deletionProjectID = projectID
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .foregroundStyle(self.theme.secondaryText)
                .help("Delete All Notes For \(projectName(projectID))")
                .accessibilityLabel("Delete all notes for \(projectName(projectID))")

            }
            .padding(.horizontal, 5)

            if !isCollapsed {

                ForEach(Array(Set(annotations.map(\.comparison))).sorted(), id: \.self) { comparison in

                    VStack(alignment: .leading, spacing: 8) {

                        Text(comparison)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(self.theme.secondaryText)
                            .padding(.horizontal, 5)

                        ForEach(annotations.filter { $0.comparison == comparison }.sorted { $0.filePath == $1.filePath ? $0.startLine < $1.startLine : $0.filePath < $1.filePath }) { annotation in
                            ReviewNoteCard(annotation: annotation, workspace: self.workspace) {
                                self.editingAnnotation = annotation
                            }
                        }

                    }

                }

            }

        }

    }

    private func header() -> some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Review Notes").font(.system(size: 16, weight: .semibold))
                Spacer()
                Menu {

                    Button("Delete All Notes…", role: .destructive) {
                        self.showsDeleteAllConfirmation = true
                    }
                    .disabled(self.review.annotations.isEmpty)

                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Review Notes Actions")
                DiffyIconButton(symbol: "xmark", label: "Close Review Notes") { self.workspace.showsReview = false }

            }

            Picker("Scope", selection: self.$scope) {
                ForEach(["Comparison", "Project", "All Projects"], id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .disabled(self.workspace.selectedProject == nil)

            TextField("Search Notes…", text: self.$query)
                .textFieldStyle(.roundedBorder)

            Toggle("Open Notes Only", isOn: self.$onlyOpen)
                .font(.system(size: 10))

            Toggle("Needs Review", isOn: self.$needsReviewOnly)
                .font(.system(size: 10))

            Text("\(self.review.annotations.count) saved notes · \(Set(self.review.annotations.map(\.projectID)).count) projects · \(self.review.annotations.filter(\.needsReview).count) need review")
                .font(.system(size: 10))
                .foregroundStyle(self.theme.secondaryText)

        }
        .padding(16)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func exportFooter() -> some View {

        VStack(spacing: 10) {

            if self.review.canUndoDelete {

                Button("Undo Deleted Notes") { self.review.undoDelete() }
                    .font(.system(size: 10))

            }

            Button {
                self.exportEverything = true
                self.showsExport = true
            } label: {

                Label("Export Everything · \(self.review.annotations.count)", systemImage: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(self.review.annotations.isEmpty)

            if self.scope != "All Projects" {

                Button("Export Current Scope · \(self.scopedAnnotations.count)") {
                    self.exportEverything = false
                    self.showsExport = true
                }
                .font(.system(size: 10))
                .disabled(self.scopedAnnotations.isEmpty)

            }

            Text("Every project, including resolved notes and files hidden by filters.")
                .font(.system(size: 9))
                .foregroundStyle(self.theme.secondaryText)
                .multilineTextAlignment(.center)

        }
        .padding(16)
        .overlay(alignment: .top) { self.theme.border.frame(height: 1) }

    }

    private func checkCurrentSources() {

        guard self.workspace.runtime.isLive, self.workspace.selectedProject != nil else { return }
        self.review.markChangedSources(
            projectID: self.workspace.project.id,
            comparison: self.workspace.comparisonTitle,
            files: self.workspace.files
        )

    }

}

#Preview {

    ReviewScreen(
        workspace: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 330, height: 700)
    .withMockPreviews()

}
