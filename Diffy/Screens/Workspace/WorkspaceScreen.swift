import SwiftUI

struct WorkspaceScreen: View {

    @StateObject var viewModel: WorkspaceViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @EnvironmentObject private var accounts: GitHubAccountsViewModel
    @ObservedObject private var repository: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reviewWidth: CGFloat = 310
    @State private var reviewDragStartWidth: CGFloat?

    init(viewModel: WorkspaceViewModel) {

        self._viewModel = StateObject(wrappedValue: viewModel)
        self._repository = ObservedObject(wrappedValue: viewModel.repositoryViewModel)

    }

    var body: some View {

        VStack(spacing: 0) {

            HStack(spacing: 0) {

                if self.viewModel.showsSidebar && self.viewModel.activePullRequestReview == nil {

                    WorkspaceSidebarPane(viewModel: self.viewModel, isOperating: self.repository.isOperating)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                }

                sizableWorkspaceContent()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .geometryGroup()
                    .compositingGroup()

                if self.viewModel.showsReview && self.viewModel.activePullRequestReview == nil {

                    HStack(spacing: 0) {

                        HorizontalResizeHandle(label: "Drag To Resize Review Notes", resizeGesture: reviewResizeGesture())

                        ReviewScreen(workspace: self.viewModel)
                            .frame(width: self.reviewWidth)

                    }
                    .geometryGroup()
                    .compositingGroup()
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
                if self.viewModel.pendingPullProjectID == project.id {
                    self.viewModel.pendingPullProjectID = nil
                    self.repository.request(.pull(.fastForwardOnly))
                }
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
            "Apply Changes Before Leaving?",
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
        .alert("Review Storage", isPresented: Binding(
            get: { self.review.errorMessage != nil },
            set: { if !$0 { self.review.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.review.errorMessage ?? "")
        }

    }

    private func reviewResizeGesture() -> some Gesture {

        DragGesture(minimumDistance: 0, coordinateSpace: .global)
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

            if let review = self.viewModel.activePullRequestReview,
               let aiWorkspace = review.aiWorkspace,
               let patchReview = review.patchReview {
                PullRequestReviewScreen(
                    viewModel: review,
                    workspace: self.viewModel,
                    aiWorkspace: aiWorkspace,
                    patchReview: patchReview
                )
            } else if self.viewModel.showsOverview || self.viewModel.projects.isEmpty {
                WorkspaceOverviewScreen(workspace: self.viewModel, viewModel: self.viewModel.overviewViewModel)
            } else {

                VStack(spacing: 0) {

                    WorkspaceHeader(viewModel: self.viewModel, repository: self.repository)

                    if let notice = self.viewModel.notice {

                        HStack {

                            DiffyStatusBanner(message: notice)
                            Button { self.viewModel.notice = nil } label: { Image(systemName: "xmark") }
                                .accessibilityLabel("Dismiss Workspace Notice")

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
            .help("Toggle Sidebar")
            .disabled(self.viewModel.activePullRequestReview != nil)

        }

        ToolbarItem(placement: .principal) {

            if let request = self.viewModel.activePullRequestReview?.request {
                navigationContextPill("#\(request.number) · \(request.link.fullName)", symbol: "arrow.triangle.pull")
            } else if self.viewModel.showsOverview {
                navigationContextPill("Workspace Overview", symbol: "square.grid.2x2")
            } else if self.viewModel.selectedProject != nil {

                navigationContextPill(
                    self.repository.snapshot?.head.displayName ?? "Local Project",
                    symbol: "arrow.triangle.branch"
                )

            } else {
                navigationContextPill("No Project Selected", symbol: "folder")

            }

        }

        ToolbarItemGroup(placement: .primaryAction) {

            Button {
                self.viewModel.showsCommandPalette = true
            } label: {
                Label("Commands", systemImage: "command")
            }
            .help("Command Palette · ⌘K")
            .disabled(self.viewModel.projects.isEmpty)

            Button {

                withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.26)) {
                    self.viewModel.showsReview.toggle()
                }

            } label: {
                Label("Review Notes", systemImage: "text.bubble")
            }
            .help("Review Notes · ⇧⌘R")
            .disabled(self.viewModel.projects.isEmpty || self.viewModel.activePullRequestReview != nil)

            SettingsLink {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .help("Open Settings")

        }

    }

    private func navigationContextPill(_ title: String, symbol: String) -> some View {

        HStack(spacing: 6) {

            Image(systemName: symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(self.theme.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)
                .lineLimit(1)

        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .background {
            Capsule()
                .fill(self.theme.elevated)
        }
        .overlay {
            Capsule()
                .strokeBorder(self.theme.border.opacity(self.theme.isDark ? 0.85 : 0.8), lineWidth: 0.75)
        }

    }

}

#Preview {

    WorkspaceScreen(
        viewModel: mockResolve(WorkspaceViewModel.self)
    )
    .withMockPreviews()

}
