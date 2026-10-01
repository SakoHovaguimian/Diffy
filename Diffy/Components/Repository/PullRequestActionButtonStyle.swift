import SwiftUI

struct PullRequestActionButtonStyle: ButtonStyle {

    let isPrimary: Bool
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {

        let shape = RoundedRectangle(cornerRadius: self.contentSize.scaled(7))
        let background = self.isPrimary ? self.theme.accent : self.theme.accent.opacity(0.04)

        return configuration.label
            .font(self.contentSize.font(size: 11, weight: .semibold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, self.contentSize.scaled(12))
            .frame(height: self.contentSize.scaled(34))
            .foregroundStyle(self.isPrimary ? Color.white : self.theme.accent)
            .background(background.opacity(configuration.isPressed ? 0.75 : 1), in: shape)
            .overlay(shape.strokeBorder(self.theme.accent.opacity(self.isPrimary ? 0.8 : 0.4), lineWidth: 1))
            .opacity(self.isEnabled ? 1 : 0.45)
            .contentShape(shape)

    }

}
