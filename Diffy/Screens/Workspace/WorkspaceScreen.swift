import SwiftUI

struct WorkspaceScreen: View {

    @StateObject var viewModel: WorkspaceViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @EnvironmentObject private var review: ReviewViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sidebarDragStartWidth: Double?
    @State private var reviewWidth: CGFloat = 310
    @State private var reviewDragStartWidth: CGFloat?

    var body: some View {

        VStack(spacing: 0) {

            HStack(spacing: 0) {

                if self.viewModel.showsSidebar {

                    WorkspaceSidebar(viewModel: self.viewModel)
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
        .navigationTitle("Diffy")
        .focusedSceneValue(\.workspace, self.viewModel)
        .toolbar { toolbarContent() }
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
                draft: draft,
                bucket: self.viewModel.buckets.first { $0.id == draft.bucketID }
            ) { project in
                self.viewModel.addProject(project)
            }
            .diffyStyle()

        }
        .sheet(item: self.$viewModel.annotationDraft) { draft in

            AnnotationEditorScreen(draft: draft, workspace: self.viewModel)
                .diffyStyle()

        }
        .sheet(isPresented: self.$viewModel.showsCommandPalette) {

            CommandPaletteScreen(workspace: self.viewModel)
                .diffyStyle()

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

        VStack(spacing: 0) {

            WorkspaceHeader(viewModel: self.viewModel)

            if self.viewModel.showsDashboard {
                ProjectDashboardScreen(workspace: self.viewModel)
            } else if self.viewModel.mode == .workingTree {
                ComparisonScreen(workspace: self.viewModel)
            } else {

                RoundedRectangle(cornerRadius: 12)
                    .fill(self.theme.added.opacity(0.28))
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(self.theme.background)

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

            HStack(spacing: 8) {

                Image(systemName: self.viewModel.project.directoryPath == nil ? "arrow.triangle.branch" : "folder")
                Text(self.viewModel.project.directoryPath == nil ? self.viewModel.project.branch : "Local folder")
                    .lineLimit(1)

            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(self.theme.secondaryText)

        }

        ToolbarItemGroup(placement: .primaryAction) {

            Button {
                self.viewModel.showsCommandPalette = true
            } label: {
                Label("Commands", systemImage: "command")
            }
            .help("Command palette · ⌘K")

            Button {

                withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.26)) {
                    self.viewModel.showsReview.toggle()
                }

            } label: {
                Label("Review notes", systemImage: "text.bubble")
            }
            .help("Review notes · ⇧⌘R")

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
