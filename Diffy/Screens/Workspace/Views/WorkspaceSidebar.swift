import SwiftUI

struct WorkspaceSidebar: View {

    @ObservedObject var viewModel: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @State private var bucketPendingDeletion: Bucket?
    @State private var bucketDropPosition: BucketDropPosition?
    private let bucketHeaderHeight: CGFloat = 30
    private let projectRowHeight: CGFloat = 34

    private var favoriteGold: Color {
        Color(hex: self.theme.isDark ? "F0C66E" : "B78635")
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            brand()
            overviewRow()
            favorites()

            self.theme.border
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            GeometryReader { geometry in

                ScrollView {

                    VStack(alignment: .leading, spacing: 0) {

                        VStack(alignment: .leading, spacing: 0) {

                            let visibleBuckets = self.viewModel.buckets.filter(\.isVisible)

                            ForEach(visibleBuckets) { bucket in

                                bucketInsertionTarget(relativeTo: bucket, placeAfter: false)
                                bucketSection(bucket)

                            }

                            if let lastBucket = visibleBuckets.last {
                                bucketInsertionTarget(relativeTo: lastBucket, placeAfter: true)
                            }

                            unassignedSection()

                        }

                        Spacer(minLength: 0)

                        recentComparisons()

                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .frame(width: geometry.size.width, alignment: .leading)

                }

            }

            sidebarFooter()

        }
        .background(self.theme.sidebar)
        .confirmationDialog(
            "Delete \(self.bucketPendingDeletion?.title ?? "Bucket")?",
            isPresented: Binding(
                get: { self.bucketPendingDeletion != nil },
                set: { if !$0 { self.bucketPendingDeletion = nil } }
            )
        ) {

            Button("Delete Bucket", role: .destructive) {

                if let bucket = self.bucketPendingDeletion {
                    self.viewModel.deleteBucket(bucket)
                }

                self.bucketPendingDeletion = nil

            }

        } message: {

            if let bucket = self.bucketPendingDeletion,
               let replacement = self.viewModel.replacementBucket(for: bucket) {
                Text("Projects in this Bucket will move to \(replacement.title). Review notes and project files stay in place.")
            }

        }

    }

    private func brand() -> some View {

        HStack(spacing: 10) {

            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 21))
                .foregroundStyle(self.theme.accent)

            Text("diffy")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .tracking(-0.8)

            Spacer()

            if let badgeTitle = self.viewModel.runtime.badgeTitle {
                DiffyBadge(title: badgeTitle, color: self.theme.secondaryText)
            }

        }
        .padding(.horizontal, 18)
        .padding(.vertical, 28)

    }

    private func overviewRow() -> some View {

        Button {
            self.viewModel.showOverview()
        } label: {

            Label("Overview", systemImage: "square.grid.2x2")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(self.viewModel.showsOverview ? self.theme.accent : self.theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(self.viewModel.showsOverview ? self.theme.selection : .clear, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 14)

    }

    private func favorites() -> some View {

        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 7) {

                Image(systemName: "star.fill")
                Text("FAVORITES").tracking(1.3)

            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(self.favoriteGold)
            .padding(.horizontal, 10)
            .padding(.bottom, 4)

            ForEach(self.viewModel.projects.filter { self.viewModel.favorites.contains($0.id) }) { project in
                projectRow(project)
            }

        }
        .padding(.horizontal, 12)
        .padding(.bottom, 14)

    }

    private func bucketSection(_ bucket: Bucket) -> some View {

        let projects = self.viewModel.orderedProjects(in: bucket.id)
        let color = Color(hex: bucket.accentHex)

        return VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 0) {

                Button {
                    toggleBucket(bucket)
                } label: {

                    HStack(spacing: 7) {

                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .rotationEffect(.degrees(bucket.isExpanded ? 90 : 0))
                            .animation(.easeInOut(duration: 0.22), value: bucket.isExpanded)
                        Image(systemName: bucket.symbol)
                            .foregroundStyle(color)
                        Text(bucket.title.uppercased())
                            .tracking(1)
                        Spacer(minLength: 0)

                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(self.theme.isDark ? color : self.theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())

                }
                .buttonStyle(.plain)
                .help(bucket.isExpanded ? "Collapse \(bucket.title)" : "Expand \(bucket.title)")
                .accessibilityLabel("\(bucket.isExpanded ? "Collapse" : "Expand") \(bucket.title)")

                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(self.theme.secondaryText)
                    .frame(width: 20, height: 28)
                    .accessibilityHidden(true)

                Menu {

                    Button("Customize Bucket") { self.viewModel.selectedBucket = bucket }
                    Button("Move Up") { self.viewModel.moveBucket(bucket, direction: -1) }
                    Button("Move Down") { self.viewModel.moveBucket(bucket, direction: 1) }
                    Divider()
                    Button("Delete Bucket", role: .destructive) { self.bucketPendingDeletion = bucket }
                        .disabled(self.viewModel.replacementBucket(for: bucket) == nil)

                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(color)
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .tint(color)
                .frame(width: 28)
                .help("Bucket Actions For \(bucket.title)")

            }
            .padding(.leading, 8)
            .frame(height: self.bucketHeaderHeight)
            .draggable(BucketDragItem(id: bucket.id))

            if bucket.isExpanded {

                ForEach(projects) { project in

                    reorderableProjectRow(project)
                        .transition(.opacity.combined(with: .move(edge: .top)))

                }

                addProjectButton(in: bucket, color: color)

            }

        }
        .padding(.vertical, 3)
        .dropDestination(for: String.self) { projectIDs, _ in

            let validIDs = projectIDs.filter { id in self.viewModel.projects.contains { $0.id == id } }

            for projectID in validIDs {
                self.viewModel.moveProject(projectID, to: bucket.id)
            }

            return !validIDs.isEmpty

        }
        .contextMenu {

            Button("Customize Bucket") { self.viewModel.selectedBucket = bucket }
            Button("Move Up") { self.viewModel.moveBucket(bucket, direction: -1) }
            Button("Move Down") { self.viewModel.moveBucket(bucket, direction: 1) }
            Button("Delete Bucket", role: .destructive) { self.bucketPendingDeletion = bucket }
                .disabled(self.viewModel.replacementBucket(for: bucket) == nil)

        }
        .background {

            if bucket.usesGradient {

                LinearGradient(colors: [color.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: bucket.cornerRadius))

            }

        }

    }

    private func bucketInsertionTarget(relativeTo bucket: Bucket, placeAfter: Bool) -> some View {

        let position = BucketDropPosition(
            targetID: bucket.id,
            placeAfter: placeAfter
        )

        return ZStack {

            Color.clear

            if self.bucketDropPosition == position {

                Capsule()
                    .fill(self.theme.accent)
                    .frame(height: 2)
                    .padding(.horizontal, 8)

            }

        }
        .frame(height: 8)
        .contentShape(Rectangle())
        .dropDestination(for: BucketDragItem.self) { items, _ in

            guard let draggedID = items.first?.id,
                  self.viewModel.buckets.contains(where: { $0.id == draggedID }) else {
                return false
            }

            withAnimation(.easeInOut(duration: 0.2)) {

                _ = self.viewModel.reorderBucket(
                    draggedID,
                    relativeTo: bucket.id,
                    placeAfter: placeAfter
                )

            }

            self.bucketDropPosition = nil
            return true

        } isTargeted: { isTargeted in

            if isTargeted {
                self.bucketDropPosition = position
            } else if self.bucketDropPosition == position {
                self.bucketDropPosition = nil
            }

        }

    }

    private func addProjectButton(in bucket: Bucket, color: Color) -> some View {

        Button {

            guard let directoryURL = ProjectDirectoryController().chooseDirectory() else {
                return
            }

            self.viewModel.prepareProject(directoryURL: directoryURL, in: bucket)

        } label: {

            Label("Add New Project", systemImage: "plus")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
                .contentShape(RoundedRectangle(cornerRadius: 8))

        }
        .buttonStyle(.plain)
        .help("Choose A Folder To Add To \(bucket.title)")

    }

    private func unassignedSection() -> some View {

        let projects = self.viewModel.orderedProjects(in: nil)

        return VStack(alignment: .leading, spacing: 6) {

            sectionLabel("UNASSIGNED")

            ForEach(projects) { project in
                reorderableProjectRow(project)
            }

            if projects.isEmpty {

                Text("Drop A Project Here To Detach")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(self.theme.border, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))

            }

        }
        .padding(.top, 14)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { projectIDs, _ in

            let validIDs = projectIDs.filter { id in self.viewModel.projects.contains { $0.id == id } }

            for projectID in validIDs {
                self.viewModel.detachProject(projectID)
            }

            return !validIDs.isEmpty

        }

    }

    private func toggleBucket(_ bucket: Bucket) {

        var updated = bucket
        updated.isExpanded.toggle()

        withAnimation(.easeInOut(duration: 0.22)) {
            self.viewModel.saveBucket(updated)
        }

    }

    private func reorderableProjectRow(_ project: RepositoryProject) -> some View {

        projectRow(project)
            .overlay {

                if self.viewModel.projectDropTargetID == project.id {

                    RoundedRectangle(cornerRadius: 7)
                        .stroke(self.theme.accent, lineWidth: 1)
                        .allowsHitTesting(false)

                }

            }
            .dropDestination(for: String.self) { projectIDs, location in

                self.viewModel.projectDropTargetID = nil

                guard projectIDs.count == 1, let draggedID = projectIDs.first else {
                    return false
                }

                return withAnimation(.easeInOut(duration: 0.2)) {

                    self.viewModel.reorderProject(
                        draggedID,
                        relativeTo: project.id,
                        placeAfter: location.y >= self.projectRowHeight / 2
                    )

                }

            } isTargeted: { isTargeted in

                if isTargeted {
                    self.viewModel.projectDropTargetID = project.id
                } else if self.viewModel.projectDropTargetID == project.id {
                    self.viewModel.projectDropTargetID = nil
                }

            }
            .help("Drop On The Upper Half To Insert Before; Lower Half To Insert After")

    }

    private func projectRow(_ project: RepositoryProject) -> some View {

        let isSelected = self.viewModel.selectedProjectID == project.id
        let color = self.viewModel.bucket(for: project).map { Color(hex: $0.accentHex) } ?? self.theme.secondaryText

        return Button {
            self.viewModel.selectProject(project)
        } label: {

            HStack(spacing: 9) {

                Image(systemName: project.symbol)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                    .frame(width: 17)

                Text(project.displayName)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if project.directoryPath == nil {

                    Text("\(project.changeCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(self.theme.secondaryText)

                }

            }
            .padding(.horizontal, 10)
            .frame(height: self.projectRowHeight)
            .background(isSelected ? color.opacity(self.theme.isDark ? 0.10 : 0.18) : .clear, in: RoundedRectangle(cornerRadius: 7))
            .overlay(alignment: .leading) {

                if isSelected && !self.theme.isDark {

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 3, height: 22)

                }

            }
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .draggable(project.id)
        .contextMenu {

            Button("Open Overview") { self.viewModel.openProjectOverview(project) }
            Button("Edit Project…") { self.viewModel.editProject(project) }
            Button("Toggle Favorite") { self.viewModel.toggleFavorite(project) }

            Menu("Move To Bucket") {

                ForEach(self.viewModel.buckets) { bucket in
                    Button(bucket.title) { self.viewModel.moveProject(project.id, to: bucket.id) }
                }

            }

            if self.viewModel.bucket(for: project) != nil {
                Button("Detach From Bucket") { self.viewModel.detachProject(project.id) }
            }

        }

    }

    private func recentComparisons() -> some View {

        VStack(alignment: .leading, spacing: 10) {

            sectionLabel("RECENT")

            ForEach(self.viewModel.recentProjectIDs, id: \.self) { id in

                if let project = self.viewModel.projects.first(where: { $0.id == id }) {

                    Button {
                        self.viewModel.openWorkingTree(for: project)

                    } label: {

                        Label(project.directoryPath == nil ? "\(project.displayName) · Working Tree" : "\(project.displayName) · Local Folder", systemImage: "clock")
                            .font(.system(size: 10))
                            .foregroundStyle(self.theme.secondaryText)
                            .lineLimit(1)

                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)

                }

            }

        }
        .padding(.top, 16)
        .padding(.bottom, 16)

    }

    private func sectionLabel(_ title: String) -> some View {

        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.3)
            .foregroundStyle(self.theme.secondaryText)
            .padding(.horizontal, 10)
            .padding(.bottom, 3)

    }

    private func sidebarFooter() -> some View {

        HStack(spacing: 8) {

            Button {
                self.viewModel.addBucket()
            } label: {

                Label("Bucket", systemImage: "plus")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(SidebarCreationButtonStyle(theme: self.theme))
            .help("Create A New Bucket")

            Button {
                addUnassignedProject()
            } label: {

                Label("Project", systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(SidebarCreationButtonStyle(theme: self.theme))
            .help("Choose A Folder To Add To Unassigned")

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Open Settings")

        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(self.theme.secondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
        .overlay(alignment: .top) { self.theme.border.frame(height: 1) }

    }

    private func addUnassignedProject() {

        guard let directoryURL = ProjectDirectoryController().chooseDirectory() else {
            return
        }

        self.viewModel.prepareProject(directoryURL: directoryURL, in: nil)

    }

}

private struct SidebarCreationButtonStyle: ButtonStyle {

    let theme: DiffyTheme

    func makeBody(configuration: Configuration) -> some View {

        configuration.label
            .lineLimit(1)
            .foregroundStyle(self.theme.isDark ? Color.white : self.theme.text)
            .frame(height: 34)
            .background(
                self.theme.isDark
                    ? self.theme.accent.opacity(configuration.isPressed ? 0.78 : 1)
                    : self.theme.surface.opacity(configuration.isPressed ? 0.72 : 1),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {

                if !self.theme.isDark {

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(self.theme.border, lineWidth: 1)

                }

            }

    }

}

private struct BucketDropPosition: Equatable {
    let targetID: String
    let placeAfter: Bool
}

#Preview {

    WorkspaceSidebar(
        viewModel: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 240, height: 750)
    .withMockPreviews()

}
