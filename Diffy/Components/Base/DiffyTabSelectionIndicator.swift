import SwiftUI

struct DiffyTabSelectionIndicator: View {

    let selectedID: String
    let bounds: [String: Anchor<CGRect>]
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {

        GeometryReader { geometry in

            if let anchor = self.bounds[self.selectedID], geometry[anchor].width.isFinite {

                let frame = geometry[anchor]
                let height = self.contentSize.scaled(2)

                self.theme.accent
                    .frame(width: max(0, frame.width), height: height)
                    .offset(x: frame.minX, y: frame.maxY - height)
                    .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.3), value: self.selectedID)

            }

        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)

    }

}
