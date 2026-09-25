import SwiftUI

struct ReviewScreen: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @State private var scope = "All Projects"
    @State private var query = ""
    @State private var onlyOpen = false
    @State private var showsExport = false
    @State private var editingAnnotation: CodeAnnotation?
    @State private var collapsedProjectIDs: Set<String> = []
    @State private var deletionProjectID: String?

    private var scopedAnnotations: [CodeAnnotation] {

        self.review.annotations.filter { annotation in

            switch self.scope {

            case "Comparison":
                annotation.projectID == self.workspace.project.id && annotation.comparison == self.workspace.comparisonTitle

            case "Project":
                annotation.projectID == self.workspace.project.id

            default:
                true

            }

        }

    }

    private var visibleAnnotations: [CodeAnnotation] {

        self.scopedAnnotations.filter {
            (!self.onlyOpen || !$0.isResolved) && (self.query.isEmpty || $0.comment.localizedCaseInsensitiveContains(self.query) || $0.filePath.localizedCaseInsensitiveContains(self.query))
        }

    }

    private var visibleProjectIDs: [String] {

        Array(Set(self.visibleAnnotations.map(\.projectID))).sorted { left, right in
            projectName(left).localizedStandardCompare(projectName(right)) == .orderedAscending
        }

    }

    private func projectName(_ projectID: String) -> String {
        self.review.annotations.first { $0.projectID == projectID }?.projectName ?? projectID
    }

    var body: some View {

        VStack(spacing: 0) {

            header()

            if self.visibleAnnotations.isEmpty {

                DiffyEmptyState(symbol: "text.bubble", title: "Room For Your Thoughts", message: "Select a line of code, then choose Annotate. Your review comes together here.")

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
                annotations: self.scopedAnnotations,
                scope: self.scope == "All Projects" ? "All Projects" : "\(self.workspace.project.displayName) · \(self.scope.lowercased())"
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

    }

    private func projectSection(_ projectID: String) -> some View {

        let annotations = self.visibleAnnotations.filter { $0.projectID == projectID }
        let isCollapsed = self.collapsedProjectIDs.contains(projectID)

        return VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 8) {

                Button {

                    if isCollapsed {
                        self.collapsedProjectIDs.remove(projectID)
                    } else {
                        self.collapsedProjectIDs.insert(projectID)
                    }

                } label: {

                    HStack(spacing: 8) {

                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                        Text(projectName(projectID))
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(annotations.count)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(self.theme.secondaryText)

                    }

                }
                .buttonStyle(.plain)
                .help(isCollapsed ? "Expand Project Notes" : "Collapse Project Notes")

                Spacer()

                Button {
                    self.deletionProjectID = projectID
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(self.theme.secondaryText)
                .help("Delete All Notes For \(projectName(projectID))")

            }
            .padding(.horizontal, 5)

            if !isCollapsed {

                ForEach(annotations) { annotation in
                    annotationCard(annotation)
                }

            }

        }

    }

    private func header() -> some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("Review Notes").font(.system(size: 16, weight: .semibold))
                Spacer()
                DiffyIconButton(symbol: "xmark", label: "Close Review Notes") { self.workspace.showsReview = false }

            }

            Picker("Scope", selection: self.$scope) {
                ForEach(["Comparison", "Project", "All Projects"], id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)

            TextField("Search Notes…", text: self.$query)
                .textFieldStyle(.roundedBorder)

            Toggle("Open Notes Only", isOn: self.$onlyOpen)
                .font(.system(size: 10))

        }
        .padding(16)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func annotationCard(_ annotation: CodeAnnotation) -> some View {

        VStack(alignment: .leading, spacing: 11) {

            Button {
                self.workspace.revealAnnotation(annotation)
            } label: {

                VStack(alignment: .leading, spacing: 5) {

                    Text((annotation.filePath as NSString).lastPathComponent)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(self.theme.accent)
                    Text("\(annotation.side.rawValue) · L\(annotation.startLine)–\(annotation.endLine)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)

                }

            }
            .buttonStyle(.plain)

            Text(annotation.comment)
                .font(.system(size: 12))
                .lineSpacing(4)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            if annotation.side == .result {

                Text("Captured result snapshot · may differ from the current draft")
                    .font(.system(size: 9))
                    .foregroundStyle(self.theme.modified)

            }

            HStack {

                Button {

                    var updated = annotation
                    updated.isResolved.toggle()
                    self.review.update(updated)

                } label: {
                    Label(annotation.isResolved ? "Resolved" : "Resolve", systemImage: annotation.isResolved ? "checkmark.circle.fill" : "circle")
                }
                .foregroundStyle(annotation.isResolved ? self.theme.added : self.theme.secondaryText)

                Spacer()
                Button("Edit") { self.editingAnnotation = annotation }

                Button { self.review.remove(annotation) } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete Annotation")

            }
            .buttonStyle(.plain)
            .font(.system(size: 10))
            .foregroundStyle(self.theme.secondaryText)

        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.theme.isDark ? self.theme.elevated : self.theme.surface, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(self.theme.border.opacity(self.theme.isDark ? 0.65 : 1)))

    }

    private func exportFooter() -> some View {

        VStack(spacing: 10) {

            if self.review.canUndoDelete {

                Button("Undo Deleted Note") { self.review.undoDelete() }
                    .font(.system(size: 10))

            }

            Button {
                self.showsExport = true
            } label: {

                Label("Export All \(self.scopedAnnotations.count) Notes", systemImage: "square.and.arrow.up")
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(self.scopedAnnotations.isEmpty)

            Text("Includes resolved notes and files hidden by filters.")
                .font(.system(size: 9))
                .foregroundStyle(self.theme.secondaryText)
                .multilineTextAlignment(.center)

        }
        .padding(16)
        .overlay(alignment: .top) { self.theme.border.frame(height: 1) }

    }

}

#Preview {

    ReviewScreen(
        workspace: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 330, height: 700)
    .withMockPreviews()

}
