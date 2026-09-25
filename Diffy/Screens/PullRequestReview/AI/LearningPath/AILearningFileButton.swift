import SwiftUI

struct AILearningFileButton: View {

    let path: String
    var label: String?
    let onOpen: () -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Button(action: self.onOpen) {

            HStack(spacing: 8) {

                DiffyPathIcon(path: self.path, size: 14)
                Text(self.label ?? self.path)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .medium))
                    .accessibilityHidden(true)

            }
            .foregroundStyle(self.theme.accent)
            .padding(.vertical, 5)
            .contentShape(Rectangle())

        }
        .buttonStyle(.borderless)
        .help("Open The Diff For \(self.path)")
        .accessibilityLabel("Open \(self.label ?? self.path)")
        .accessibilityHint(self.path)

    }

}
