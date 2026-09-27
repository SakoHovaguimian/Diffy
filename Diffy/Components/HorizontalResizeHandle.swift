import SwiftUI

struct HorizontalResizeHandle<ResizeGesture: Gesture>: View {

    let label: String
    let leftBackground: Color
    private let rightBackground = Color(hex: "1A2430")
    let resizeGesture: ResizeGesture
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 0) {

            self.leftBackground
            self.rightBackground

        }
        .frame(width: 20)
        .overlay {
            self.theme.border.frame(width: self.theme.isDark ? 5 : 1)
        }
        .overlay {

            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(self.theme.secondaryText)
                .frame(width: 20, height: 24)
                .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(self.theme.border, lineWidth: 1))
                .accessibilityHidden(true)
                .allowsHitTesting(false)

        }
        .background(ResizeCursorView())
        .contentShape(Rectangle())
        .gesture(self.resizeGesture)
        .help(self.label)
        .accessibilityLabel(self.label)

    }

}
