import SwiftUI

struct WorkspaceSidebar: View {

    @ObservedObject var viewModel: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @State private var bucketPendingDeletion: Bucket?
    @State private var bucketDropTargetID: String?
    private let bucketHeaderHeight: CGFloat = 30

    private var favoriteGold: Color {
        Color(hex: self.theme.isDark ? "F0C66E" : "B78635")
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            brand()
            favorites()

            self.theme.border
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            GeometryReader { geometry in

                ScrollView {

                    VStack(alignment: .leading, spacing: 0) {

                        VStack(alignment: .leading, spacing: 8) {

                            ForEach(self.viewModel.buckets.filter(\.isVisible)) { bucket in
                                bucketSection(bucket)
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
            DiffyBadge(title: "PREVIEW", color: self.theme.secondaryText)

        }
        .padding(.horizontal, 18)
        .padding(.vertical, 28)

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

        let projects = self.viewModel.projects.filter { self.viewModel.bucketID(for: $0) == bucket.id }
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
                        Text(bucket.title.uppercased())
                            .tracking(1)
                        Spacer(minLength: 0)

                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())

                }
                .buttonStyle(.plain)
                .help(bucket.isExpanded ? "Collapse \(bucket.title)" : "Expand \(bucket.title)")
                .accessibilityLabel("\(bucket.isExpanded ? "Collapse" : "Expand") \(bucket.title)")

                Menu {

                    Button("Customize Bucket") { self.viewModel.selectedBucket = bucket }
                    Button("Move up") { self.viewModel.moveBucket(bucket, direction: -1) }
                    Button("Move down") { self.viewModel.moveBucket(bucket, direction: 1) }
                    Divider()
                    Button("Delete Bucket", role: .destructive) { self.bucketPendingDeletion = bucket }
                        .disabled(self.viewModel.replacementBucket(for: bucket) == nil)

                } label: {
                    Image(systemName: "ellipsis").frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 28)
                .help("Bucket actions for \(bucket.title)")

            }
            .padding(.leading, 8)
            .frame(height: self.bucketHeaderHeight)
            .background {

                if self.bucketDropTargetID == bucket.id {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(self.theme.accent.opacity(0.14))
                }

            }
            .draggable(BucketDragItem(id: bucket.id))
            .dropDestination(for: BucketDragItem.self) { items, location in

                guard let draggedID = items.first?.id,
                      self.viewModel.buckets.contains(where: { $0.id == draggedID }) else {
                    return false
                }

                withAnimation(.easeInOut(duration: 0.2)) {
                    _ = self.viewModel.reorderBucket(
                        draggedID,
                        relativeTo: bucket.id,
                        placeAfter: location.y >= self.bucketHeaderHeight / 2
                    )
                }

                self.bucketDropTargetID = nil
                return true

            } isTargeted: { isTargeted in

                if isTargeted {
                    self.bucketDropTargetID = bucket.id
                } else if self.bucketDropTargetID == bucket.id {
                    self.bucketDropTargetID = nil
                }

            }

            if bucket.isExpanded {

                ForEach(projects) { project in
                    projectRow(project)
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
            Button("Move up") { self.viewModel.moveBucket(bucket, direction: -1) }
            Button("Move down") { self.viewModel.moveBucket(bucket, direction: 1) }
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
        .help("Choose a folder to add to \(bucket.title)")

    }

    private func unassignedSection() -> some View {

        let projects = self.viewModel.projects.filter { self.viewModel.bucket(for: $0) == nil }

        return VStack(alignment: .leading, spacing: 6) {

            sectionLabel("UNASSIGNED")

            ForEach(projects) { project in
                projectRow(project)
            }

            if projects.isEmpty {

                Text("Drop a project here to detach")
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

                Text(project.name)
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
            .padding(.vertical, 9)
            .background(isSelected ? color.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .draggable(project.id)
        .contextMenu {

            Button("Open overview") { self.viewModel.selectProject(project) }
            Button("Toggle favorite") { self.viewModel.toggleFavorite(project) }

            Menu("Move to Bucket") {

                ForEach(self.viewModel.buckets) { bucket in
                    Button(bucket.title) { self.viewModel.moveProject(project.id, to: bucket.id) }
                }

            }

            if self.viewModel.bucket(for: project) != nil {
                Button("Detach from Bucket") { self.viewModel.detachProject(project.id) }
            }

        }

    }

    private func recentComparisons() -> some View {

        VStack(alignment: .leading, spacing: 10) {

            sectionLabel("RECENT")

            ForEach(self.viewModel.recentProjectIDs, id: \.self) { id in

                if let project = self.viewModel.projects.first(where: { $0.id == id }) {

                    Button {

                        self.viewModel.selectProject(project)
                        self.viewModel.selectMode(.workingTree)

                    } label: {

                        Label(project.directoryPath == nil ? "\(project.name) · working tree" : "\(project.name) · local folder", systemImage: "clock")
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

        HStack {

            Button {
                self.viewModel.addBucket()
            } label: {
                Label("New Bucket", systemImage: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(self.theme.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .help("Create a new Bucket")

            Spacer()

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Open settings")

        }
        .font(.system(size: 11))
        .foregroundStyle(self.theme.secondaryText)
        .padding(20)
        .overlay(alignment: .top) { self.theme.border.frame(height: 1) }

    }

}

#Preview {

    WorkspaceSidebar(
        viewModel: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 240, height: 750)
    .withMockPreviews()

}
