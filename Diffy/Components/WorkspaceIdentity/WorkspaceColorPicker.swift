import SwiftUI

struct WorkspaceColorPicker: View {

    @Binding var accentHex: String
    @Environment(\.diffyTheme) private var theme
    private let accents = ["7862D9", "319B90", "D39553", "CD7293", "548FC5", "7C9D5B"]

    private var customColor: Binding<Color> {

        Binding(
            get: { Color(hex: self.accentHex) },
            set: { color in

                if let hex = color.rgbHex { self.accentHex = hex }

            }
        )

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 12) {

                ForEach(self.accents, id: \.self) { hex in

                    Button { self.accentHex = hex } label: {

                        Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                            .overlay(Circle().stroke(self.theme.text.opacity(self.accentHex == hex ? 0.6 : 0), lineWidth: 2).padding(-3))

                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Accent \(hex)")
                    .accessibilityAddTraits(self.accentHex == hex ? .isSelected : [])

                }

            }
            .padding(.vertical, 5)

            ColorPicker("Custom Color", selection: self.customColor, supportsOpacity: false)

        }
        .font(.system(size: 12))

    }

}
