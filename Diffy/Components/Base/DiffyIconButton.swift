import SwiftUI

struct DiffyIconButton: View {

    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    let symbol: String
    let label: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {

        Button(action: self.action) {

            Image(systemName: self.symbol)
                .font(self.contentSize.font(size: 13, weight: .medium))
                .frame(width: self.contentSize.scaled(28), height: self.contentSize.scaled(28))
                .foregroundStyle(self.isSelected ? self.theme.accent : self.theme.secondaryText)
                .background(self.isSelected ? self.theme.selection : .clear, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(6)))

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
