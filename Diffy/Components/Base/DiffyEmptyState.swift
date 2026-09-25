import SwiftUI

struct DiffyEmptyState: View {

    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    let symbol: String
    let title: String
    let message: String

    var body: some View {

        VStack(spacing: self.contentSize.scaled(12)) {

            Image(systemName: self.symbol)
                .font(self.contentSize.font(size: 30, weight: .light))
                .foregroundStyle(self.theme.accent)
                .padding(.bottom, self.contentSize.scaled(6))

            Text(self.title)
                .font(self.contentSize.font(size: 16, weight: .semibold))

            Text(self.message)
                .font(self.contentSize.font(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: self.contentSize.scaled(290))

        }
        .padding(self.contentSize.scaled(28))
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

}

#Preview {

    DiffyEmptyState(
        symbol: "doc.text.magnifyingglass",
        title: "Choose A File",
        message: "Select a file to inspect its changes."
    )
    .frame(width: 420, height: 280)
    .withMockPreviews()

}
