import SwiftUI

struct DiffyStatusBanner: View {

    let message: String
    var isError = false
    var onDismiss: (() -> Void)? = nil
    @Environment(\.diffyTheme) private var theme
    @State private var isDismissed = false

    var body: some View {

        Group {

            if !self.isDismissed {

                HStack(spacing: 12) {

                    Label(self.message, systemImage: self.isError ? "exclamationmark.circle" : "info.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {

                        if let onDismiss = self.onDismiss {
                            onDismiss()
                        } else {
                            self.isDismissed = true
                        }

                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss Message")
                    .help("Dismiss Message")

                }
                .font(.system(size: 12))
                .foregroundStyle(self.isError ? self.theme.removed : self.theme.secondaryText)
                .textSelection(.enabled)
                .padding(12)
                .background((self.isError ? self.theme.removed : self.theme.accent).opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                .id(self.message)
                .transition(.blurReplace)

            }

        }
        .diffyStatusAnimation(value: self.isDismissed)
        .onChange(of: self.message) { _, _ in self.isDismissed = false }

    }

}
