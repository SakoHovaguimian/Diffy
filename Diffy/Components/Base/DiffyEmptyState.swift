import SwiftUI

struct DiffyEmptyState: View {

    @Environment(\.diffyTheme) private var theme
    let symbol: String
    let title: String
    let message: String

    var body: some View {

        VStack(spacing: 12) {

            Image(systemName: self.symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(self.theme.accent)
                .padding(.bottom, 6)

            Text(self.title)
                .font(.system(size: 16, weight: .semibold))

            Text(self.message)
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 290)

        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }

}

#Preview {

    DiffyEmptyState(
        symbol: "doc.text.magnifyingglass",
        title: "Choose a file",
        message: "Select a file to inspect its changes."
    )
    .frame(width: 420, height: 280)
    .withMockPreviews()

}
