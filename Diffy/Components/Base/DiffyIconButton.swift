import SwiftUI

struct DiffyIconButton: View {

    @Environment(\.diffyTheme) private var theme
    let symbol: String
    let label: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {

        Button(action: self.action) {

            Image(systemName: self.symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
                .foregroundStyle(self.isSelected ? self.theme.accent : self.theme.secondaryText)
                .background(self.isSelected ? self.theme.selection : .clear, in: RoundedRectangle(cornerRadius: 6))

        }
        .buttonStyle(.plain)
        .help(self.label)
        .accessibilityLabel(self.label)

    }

}

#Preview {

    DiffyIconButton(
        symbol: "magnifyingglass",
        label: "Find in comparison"
    ) {}
    .padding(24)
    .withMockPreviews()

}
