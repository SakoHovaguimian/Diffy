import SwiftUI

struct AIArchitectureMapView: View {

    let response: ArchitectureMapResponse
    let generation: AIReviewGeneration
    let onOpenFile: (AIReviewGeneration, String) -> Void
    @Binding var selectedNodeID: String?
    @Environment(\.diffyTheme) private var theme

    private var selectedNode: ArchitectureNode? {
        self.response.nodes.first { $0.id == self.selectedNodeID } ?? self.response.nodes.first
    }

    var body: some View {

        HStack(spacing: 0) {

            VStack(alignment: .leading, spacing: 0) {

                introduction()
                legend()
                ScrollView([.horizontal, .vertical]) {

                    AIArchitectureGraph(
                        nodes: self.response.nodes,
                        edges: self.response.edges,
                        selectedNodeID: self.selectedNode?.id,
                        select: { self.selectedNodeID = $0 }
                    )
                    .padding(24)

                }

            }
            .frame(minWidth: 410, maxWidth: .infinity)
            self.theme.border.frame(width: 1)
            inspector()
                .frame(width: 320)

        }

    }

    private func introduction() -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(self.response.title)
                .font(.system(size: 20, weight: .semibold))
            Text(self.response.overview)
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 12)
        .textSelection(.enabled)

    }

    private func legend() -> some View {

        VStack(alignment: .leading, spacing: 5) {

            HStack(spacing: 12) {

                legendItem("Changed", color: self.theme.accent)
                legendItem("Affected", color: self.theme.modified)
                legendItem("New Dependency", color: self.theme.changed)
                legendItem("Unchanged", color: self.theme.secondaryText)

            }
            HStack(spacing: 14) {

                Label("Data Flow", systemImage: "arrow.right")
                    .foregroundStyle(self.theme.changed)
                Label("Control Flow", systemImage: "arrow.right")
                    .foregroundStyle(self.theme.secondaryText)
                Label("Dependency", systemImage: "arrow.right")
                    .foregroundStyle(self.theme.secondaryText)

            }

        }
        .font(.system(size: 10))
        .padding(.horizontal, 24)
        .padding(.bottom, 12)

    }

    private func legendItem(_ title: String, color: Color) -> some View {

        HStack(spacing: 5) {

            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).foregroundStyle(self.theme.secondaryText)

        }

    }

    @ViewBuilder
    private func inspector() -> some View {

        if let node = self.selectedNode {

            ScrollView {

                VStack(alignment: .leading, spacing: 19) {

                    HStack(spacing: 8) {

                        Text(node.kind.title.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(self.theme.secondaryText)
                        Spacer()
                        DiffyBadge(title: node.change.title, color: node.change.color(in: self.theme), size: .small)

                    }
                    Text(node.label)
                        .font(.system(size: 17, weight: .semibold))
                    section("Responsibility", text: node.responsibility)
                    section("Why It Matters", text: node.whyItMatters)
                    relationshipSection("Incoming", edges: self.response.edges.filter { $0.targetID == node.id }, otherID: \.sourceID)
                    relationshipSection("Outgoing", edges: self.response.edges.filter { $0.sourceID == node.id }, otherID: \.targetID)
                    if !node.relevantSymbols.isEmpty {
                        listSection("Relevant Symbols", values: node.relevantSymbols)
                    }
                    if !node.changedFiles.isEmpty {

                        VStack(alignment: .leading, spacing: 8) {

                            sectionLabel("Changed Files")
                            ForEach(node.changedFiles, id: \.self) { path in
                                Button {
                                    self.onOpenFile(self.generation, path)
                                } label: {
                                    Label(path, systemImage: "doc.text.magnifyingglass")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(self.theme.accent)
                            }

                        }

                    }

                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            .background(self.theme.surface)
            .textSelection(.enabled)

        }

    }

    private func section(_ title: String, text: String) -> some View {

        VStack(alignment: .leading, spacing: 7) {

            sectionLabel(title)
            Text(text).font(.system(size: 12))

        }

    }

    private func listSection(_ title: String, values: [String]) -> some View {

        VStack(alignment: .leading, spacing: 7) {

            sectionLabel(title)
            ForEach(values, id: \.self) { value in
                Text(value).font(.system(size: 11, design: .monospaced))
            }

        }

    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(self.theme.secondaryText)
    }

    @ViewBuilder
    private func relationshipSection(
        _ title: String,
        edges: [ArchitectureEdge],
        otherID: KeyPath<ArchitectureEdge, String>
    ) -> some View {

        if !edges.isEmpty {

            VStack(alignment: .leading, spacing: 7) {

                sectionLabel(title)
                ForEach(edges) { edge in

                    let otherLabel = self.response.nodes.first { $0.id == edge[keyPath: otherID] }?.label ?? edge[keyPath: otherID]
                    Button {
                        self.selectedNodeID = edge[keyPath: otherID]
                    } label: {
                        Text("\(otherLabel) · \(edge.kind.title)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(self.theme.accent)
                    if !edge.label.isEmpty {
                        Text(edge.label)
                            .font(.system(size: 11))
                            .foregroundStyle(self.theme.secondaryText)
                    }

                }

            }

        }

    }

}

extension ArchitectureNodeKind {

    var title: String {

        switch self {

        case .view: "Views"
        case .viewModel: "ViewModels"
        case .service: "Services"
        case .api: "API"
        case .model: "Models"
        case .persistence: "Persistence"
        case .other: "Other"

        }

    }

}

extension ArchitectureChangeKind {

    var title: String {

        switch self {

        case .changed: "Changed"
        case .existingAffected: "Affected"
        case .unchangedDependency: "Unchanged Dependency"
        case .newDependency: "New Dependency"

        }

    }

    func color(in theme: DiffyTheme) -> Color {

        switch self {

        case .changed: theme.accent
        case .existingAffected: theme.modified
        case .unchangedDependency: theme.secondaryText
        case .newDependency: theme.changed

        }

    }

}

extension ArchitectureRelationshipKind {

    var title: String {

        switch self {

        case .dataFlow: "Data Flow"
        case .controlFlow: "Control Flow"
        case .dependency: "Dependency"

        }

    }

}
