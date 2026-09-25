import SwiftUI

struct AIArchitectureGraph: View {

    let nodes: [ArchitectureNode]
    let edges: [ArchitectureEdge]
    let selectedNodeID: String?
    let select: (String) -> Void
    @Environment(\.diffyTheme) private var theme

    private let columns: [ArchitectureNodeKind] = [.view, .viewModel, .service, .api, .model, .persistence, .other]
    private let columnWidth: CGFloat = 214
    private let rowHeight: CGFloat = 104

    private var graphWidth: CGFloat { CGFloat(self.columns.count) * self.columnWidth }
    private var graphHeight: CGFloat {
        let largestColumn = self.columns.map { kind in self.nodes.filter { $0.kind == kind }.count }.max() ?? 1
        return max(250, CGFloat(largestColumn) * self.rowHeight + 90)
    }

    var body: some View {

        ZStack(alignment: .topLeading) {

            Canvas { context, _ in

                for edge in self.edges {

                    guard let source = self.point(for: edge.sourceID), let target = self.point(for: edge.targetID) else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x: source.x + 91, y: source.y))
                    path.addLine(to: CGPoint(x: target.x - 91, y: target.y))
                    context.stroke(path, with: .color(self.edgeColor(edge)), style: StrokeStyle(lineWidth: 1.5, dash: edge.kind == .dependency ? [4, 4] : []))

                }

            }
            ForEach(self.columns, id: \.self) { kind in

                Text(kind.title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(self.theme.secondaryText)
                    .frame(width: 184)
                    .position(x: self.xPosition(for: kind), y: 18)

            }
            ForEach(self.nodes) { node in
                nodeButton(node)
                    .position(self.point(for: node.id) ?? .zero)
            }

        }
        .frame(width: self.graphWidth, height: self.graphHeight)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border, lineWidth: 1))

    }

    private func nodeButton(_ node: ArchitectureNode) -> some View {

        let isSelected = self.selectedNodeID == node.id
        let nodeColor = node.change.color(in: self.theme)

        return Button {
            self.select(node.id)
        } label: {

            HStack(alignment: .top, spacing: 8) {

                RoundedRectangle(cornerRadius: 2)
                    .fill(nodeColor)
                    .frame(width: 4)
                VStack(alignment: .leading, spacing: 5) {

                    Text(node.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(self.theme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(node.change.title)
                        .font(.system(size: 9))
                        .foregroundStyle(nodeColor)

                }
                Spacer(minLength: 0)

            }
            .padding(9)
            .frame(width: 184, height: 65)
            .background(isSelected ? self.theme.selection : self.theme.elevated, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(isSelected ? self.theme.accent : self.theme.border, lineWidth: 1))

        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(node.label), \(node.kind.title), \(node.change.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])

    }

    private func edgeColor(_ edge: ArchitectureEdge) -> Color {

        if edge.sourceID == self.selectedNodeID || edge.targetID == self.selectedNodeID {
            return self.theme.accent
        }

        return edge.kind == .dataFlow ? self.theme.changed.opacity(0.65) : self.theme.secondaryText.opacity(0.4)

    }

    private func point(for id: String) -> CGPoint? {

        guard let node = self.nodes.first(where: { $0.id == id }) else { return nil }
        let columnNodes = self.nodes.filter { $0.kind == node.kind }
        guard let row = columnNodes.firstIndex(where: { $0.id == id }) else { return nil }

        return CGPoint(x: self.xPosition(for: node.kind), y: 79 + CGFloat(row) * self.rowHeight)

    }

    private func xPosition(for kind: ArchitectureNodeKind) -> CGFloat {

        guard let column = self.columns.firstIndex(of: kind) else { return 0 }
        return CGFloat(column) * self.columnWidth + self.columnWidth / 2

    }

}
