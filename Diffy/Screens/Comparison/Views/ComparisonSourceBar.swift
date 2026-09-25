import SwiftUI

struct ComparisonSourceBar: View {

    @ObservedObject var workspace: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme

    private var choices: [String] {

        if self.workspace.mode == .branches {
            return ["main", "develop", "feature/refine-the-details"]
        }

        return self.workspace.project.commits.map(\.id)

    }

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: self.workspace.mode.symbol)
                .foregroundStyle(self.theme.accent)

            Picker("From", selection: self.$workspace.comparisonLeft) {
                ForEach(self.choices, id: \.self) { Text($0).tag($0) }
            }
            .frame(maxWidth: 270)

            Image(systemName: "arrow.right")
                .foregroundStyle(self.theme.secondaryText)

            Picker("To", selection: self.$workspace.comparisonRight) {
                ForEach(self.choices, id: \.self) { Text($0).tag($0) }
            }
            .frame(maxWidth: 270)

            Spacer()
            DiffyBadge(title: "Sample comparison", color: self.theme.secondaryText)

        }
        .font(.system(size: 11))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
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
