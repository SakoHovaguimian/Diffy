import SwiftUI

struct DiffyTimelineRow<Content: View>: View {

    let showsPreviousConnector: Bool
    let showsNextConnector: Bool
    private let content: Content
    @Environment(\.diffyTheme) private var theme

    init(
        showsPreviousConnector: Bool,
        showsNextConnector: Bool,
        @ViewBuilder content: () -> Content
    ) {

        self.showsPreviousConnector = showsPreviousConnector
        self.showsNextConnector = showsNextConnector
        self.content = content()

    }

    var body: some View {

        HStack(alignment: .top, spacing: 14) {

            Color.clear.frame(width: 9, height: 9)
            self.content

        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {

            GeometryReader { geometry in

                VStack(spacing: 0) {

                    self.theme.border
                        .frame(width: 1, height: 14)
                        .opacity(self.showsPreviousConnector ? 1 : 0)
                    Circle()
                        .stroke(self.theme.accent, lineWidth: 2)
                        .frame(width: 9, height: 9)
                    self.theme.border
                        .frame(width: 1, height: max(0, geometry.size.height - 23))
                        .opacity(self.showsNextConnector ? 1 : 0)

                }

            }
            .frame(width: 9)
            .accessibilityHidden(true)
            .allowsHitTesting(false)

        }

    }

}
