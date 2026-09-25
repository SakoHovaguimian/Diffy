import SwiftUI

struct WorkspaceScreen: View {

    @StateObject var viewModel: WorkspaceViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @EnvironmentObject private var accounts: GitHubAccountsViewModel
    @ObservedObject private var repository: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sidebarDragStartWidth: Double?
    @State private var reviewWidth: CGFloat = 310
    @State private var reviewDragStartWidth: CGFloat?

    init(viewModel: WorkspaceViewModel) {

        self._viewModel = StateObject(wrappedValue: viewModel)
        self._repository = ObservedObject(wrappedValue: viewModel.repositoryViewModel)

    }

    var body: some View {

        VStack(spacing: 0) {

            HStack(spacing: 0) {

                if self.viewModel.showsSidebar {

                    WorkspaceSidebar(viewModel: self.viewModel)
                        .disabled(self.repository.isOperating)
                        .frame(width: max(214, self.settings.appearance.sidebarWidth))
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    Rectangle()
                        .fill(self.theme.border)
                        .frame(width: 5)
                        .contentShape(Rectangle())
                        .gesture(sidebarResizeGesture())
                        .help("Drag to resize sidebar")

                }

                sizableWorkspaceContent()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if self.viewModel.showsReview {

                    Rectangle()
                        .fill(self.theme.border)
                        .frame(width: 5)
                        .contentShape(Rectangle())
                        .gesture(reviewResizeGesture())
                        .help("Drag to resize review notes")
                        .transition(.opacity)

                    ReviewScreen(workspace: self.viewModel)
                        .frame(width: self.reviewWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                }

            }
            .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.26), value: self.viewModel.showsSidebar)
            .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.26), value: self.viewModel.showsReview)

        }
        .frame(minWidth: 1050, minHeight: 650)
        .background(self.theme.background)
        .navigationTitle(self.viewModel.runtime.windowTitle)
        .focusedSceneValue(\.workspace, self.viewModel)
        .toolbar { toolbarContent() }
        .task(id: "\(self.viewModel.selectedProjectID)|\(self.viewModel.showsOverview)") {

            if !self.viewModel.showsOverview, let project = self.viewModel.selectedProject {

                await self.repository.load(project)
                guard !Task.isCancelled, self.repository.project?.id == project.id else { return }
                if !self.viewModel.showsDashboard { self.repository.activate(self.viewModel.mode) }

            }

        }
        .onReceive(self.accounts.$libraryRevision.dropFirst()) { _ in self.viewModel.reloadProjects() }
        .sheet(item: self.$viewModel.selectedBucket) { bucket in

            BucketEditorScreen(
                bucket: bucket,
                save: { self.viewModel.saveBucket($0) },
                delete: self.viewModel.replacementBucket(for: bucket) == nil ? nil : { self.viewModel.deleteBucket($0) },
                replacementBucketName: self.viewModel.replacementBucket(for: bucket)?.title
            )
            .diffyStyle()

        }
        .sheet(item: self.$viewModel.pendingProject) { draft in

            ProjectEditorScreen(
                draft: Binding(
                    get: { self.viewModel.pendingProject ?? draft },
                    set: { self.viewModel.pendingProject = $0 }
                ),
                bucket: self.viewModel.buckets.first { $0.id == draft.bucketID },
                errorMessage: self.viewModel.projectEditorError
            ) { project in
                self.viewModel.saveProject(project)
            }
            .diffyStyle()

        }
        .sheet(item: Binding(
            get: { self.repository.showsPatch ? nil : self.viewModel.annotationDraft },
            set: { self.viewModel.annotationDraft = $0 }
        )) { draft in

            AnnotationEditorScreen(draft: draft, workspace: self.viewModel)
                .diffyStyle()

        }
        .sheet(isPresented: self.$viewModel.showsCommandPalette) {

            CommandPaletteScreen(workspace: self.viewModel)
                .diffyStyle()

        }
        .confirmationDialog(
            "Apply changes before leaving?",
            isPresented: Binding(
                get: { self.viewModel.pendingDiffNavigation != nil },
                set: { if !$0, self.viewModel.pendingDiffNavigation != nil { self.viewModel.resolvePendingDiffNavigation(.cancel) } }
            ),
            titleVisibility: .visible
        ) {

            Button("Apply Changes") {
                self.viewModel.resolvePendingDiffNavigation(.apply)
            }

            Button("Discard Changes", role: .destructive) {
                self.viewModel.resolvePendingDiffNavigation(.discard)
            }

            Button("Cancel", role: .cancel) {
                self.viewModel.resolvePendingDiffNavigation(.cancel)
            }

        } message: {
            Text("The current draft has unapplied edits. Apply them to Diffy's in-memory working copy, discard them, or stay on this comparison.")
        }
        .alert("Review storage", isPresented: Binding(
            get: { self.review.errorMessage != nil },
            set: { if !$0 { self.review.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.review.errorMessage ?? "")
        }

    }

    private func sidebarResizeGesture() -> some Gesture {

        DragGesture(minimumDistance: 0)
            .onChanged { value in

                if self.sidebarDragStartWidth == nil {
                    self.sidebarDragStartWidth = self.settings.appearance.sidebarWidth
                }

                let startingWidth = self.sidebarDragStartWidth ?? self.settings.appearance.sidebarWidth
                self.settings.appearance.sidebarWidth = min(320, max(214, startingWidth + value.translation.width))

            }
            .onEnded { _ in
                self.sidebarDragStartWidth = nil
            }

    }

    private func reviewResizeGesture() -> some Gesture {

        DragGesture(minimumDistance: 0)
            .onChanged { value in

                if self.reviewDragStartWidth == nil {
                    self.reviewDragStartWidth = self.reviewWidth
                }

                let startingWidth = self.reviewDragStartWidth ?? self.reviewWidth
                self.reviewWidth = min(400, max(270, startingWidth - value.translation.width))

            }
            .onEnded { _ in
                self.reviewDragStartWidth = nil
            }

    }

    // MARK: - Workspace

    private func sizableWorkspaceContent() -> some View {

        workspaceContent()
            .diffyContentSize(self.viewModel.contentSizeScale)
            .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.24), value: self.viewModel.contentSizeScale)

    }

    private func workspaceContent() -> some View {

        Group {

            if self.viewModel.showsOverview || self.viewModel.projects.isEmpty {
                WorkspaceOverviewScreen(workspace: self.viewModel, viewModel: self.viewModel.overviewViewModel)
            } else {

                VStack(spacing: 0) {

                    WorkspaceHeader(viewModel: self.viewModel, repository: self.repository)

                    if let notice = self.viewModel.notice {

                        HStack {

                            DiffyStatusBanner(message: notice)
                            Button { self.viewModel.notice = nil } label: { Image(systemName: "xmark") }
                                .accessibilityLabel("Dismiss workspace notice")

                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    }

                    if !self.viewModel.runtime.isLive && !self.viewModel.showsDashboard && [.workingTree, .merge].contains(self.viewModel.mode) {

                        ComparisonScreen(workspace: self.viewModel)

                    } else {

                        RepositoryWorkspaceScreen(viewModel: self.repository, workspace: self.viewModel)

                    }

                }

            }

        }

    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {

        ToolbarItem(placement: .navigation) {

            Button {

                withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.26)) {
                    self.viewModel.showsSidebar.toggle()
                }

            } label: {
                Image(systemName: "sidebar.left")
            }
            .help("Toggle sidebar")

        }

        ToolbarItem(placement: .principal) {

            if self.viewModel.showsOverview {
                Text("Workspace overview")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)
            } else if self.viewModel.selectedProject != nil {

                HStack(spacing: 8) {

                    Image(systemName: "arrow.triangle.branch")
                    Text(self.repository.snapshot?.head.displayName ?? "Local project")
                        .lineLimit(1)

                }
                .padding(.horizontal, 6)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)

            } else {
                Text("No project selected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)

            }

        }

        ToolbarItemGroup(placement: .primaryAction) {

            Button {
                self.viewModel.showsCommandPalette = true
            } label: {
                Label("Commands", systemImage: "command")
            }
            .help("Command palette · ⌘K")
            .disabled(self.viewModel.projects.isEmpty)

            Button {

                withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.26)) {
                    self.viewModel.showsReview.toggle()
                }

            } label: {
                Label("Review notes", systemImage: "text.bubble")
            }
            .help("Review notes · ⇧⌘R")
            .disabled(self.viewModel.projects.isEmpty)

            SettingsLink {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .help("Open settings")

        }

    }

}

#Preview {

    WorkspaceScreen(
        viewModel: mockResolve(WorkspaceViewModel.self)
    )
    .withMockPreviews()

}
