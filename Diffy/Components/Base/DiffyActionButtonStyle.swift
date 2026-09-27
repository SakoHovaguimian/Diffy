import SwiftUI

struct DiffyActionButtonStyle: ButtonStyle {

    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {

        let shape = RoundedRectangle(cornerRadius: self.contentSize.scaled(8))

        return configuration.label
            .font(self.contentSize.font(size: 12, weight: .semibold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, self.contentSize.scaled(14))
            .frame(height: self.contentSize.scaled(36))
            .foregroundStyle(self.theme.text.opacity(self.isEnabled ? 1 : 0.45))
            .background(configuration.isPressed ? self.theme.selection : self.theme.elevated, in: shape)
            .overlay(shape.strokeBorder(self.theme.accent.opacity(self.isEnabled ? 0.4 : 0.15), lineWidth: 1))
            .contentShape(shape)

    }

}
