import SwiftUI

struct ComparisonSourceBar: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var choices: [String] {

        if self.workspace.mode == .branches {
            return ["main", "develop", "feature/refine-the-details"]
        }

        return self.workspace.project.commits.map(\.id)

    }

    var body: some View {

        HStack(spacing: self.contentSize.scaled(12)) {

            Image(systemName: self.workspace.mode.symbol)
                .foregroundStyle(self.theme.accent)

            Picker("From", selection: self.$workspace.comparisonLeft) {
                ForEach(self.choices, id: \.self) { Text($0).tag($0) }
            }
            .frame(maxWidth: self.contentSize.scaled(270))

            Image(systemName: "arrow.right")
                .foregroundStyle(self.theme.secondaryText)

            Picker("To", selection: self.$workspace.comparisonRight) {
                ForEach(self.choices, id: \.self) { Text($0).tag($0) }
            }
            .frame(maxWidth: self.contentSize.scaled(270))

            Spacer()
            DiffyBadge(title: "Sample comparison", color: self.theme.secondaryText)

        }
        .font(self.contentSize.font(size: 11))
        .padding(.horizontal, self.contentSize.scaled(18))
        .padding(.vertical, self.contentSize.scaled(12))
        .background(self.theme.elevated)

    }

}

#Preview {

    ComparisonSourceBar(
        workspace: mockResolveWorkspace(mode: .branches)
    )
    .frame(width: 950)
    .withMockPreviews()

}
