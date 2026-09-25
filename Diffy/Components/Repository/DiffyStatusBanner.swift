import SwiftUI

struct DiffyStatusBanner: View {

    let message: String
    var isError = false
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Label(self.message, systemImage: self.isError ? "exclamationmark.circle" : "info.circle")
            .font(.system(size: 12))
            .foregroundStyle(self.isError ? self.theme.removed : self.theme.secondaryText)
            .textSelection(.enabled)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((self.isError ? self.theme.removed : self.theme.accent).opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .combine)

    }

}
