import SwiftUI

struct DiffyPageHeading: View {

    let eyebrow: String
    let title: String
    let detail: String
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var size

    var body: some View {

        VStack(alignment: .leading, spacing: self.size.scaled(8)) {

            Text(self.eyebrow.uppercased())
                .font(self.size.font(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(self.theme.accent)
            Text(self.title)
                .font(self.size.font(size: 28, weight: .semibold))
                .tracking(-0.7)
            Text(self.detail)
                .font(self.size.font(size: 12))
                .foregroundStyle(self.theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

}
