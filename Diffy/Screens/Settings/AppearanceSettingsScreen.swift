import SwiftUI

struct AppearanceSettingsScreen: View {

    @EnvironmentObject private var viewModel: SettingsViewModel
    @Environment(\.diffyTheme) private var theme
    private let accents = ["7862D9", "319B90", "D39553", "CD7293", "548FC5", "7C9D5B"]

    private var customAccentColor: Binding<Color> {

        Binding(
            get: { Color(hex: self.viewModel.appearance.accentHex) },
            set: { color in

                guard let hex = color.rgbHex else {
                    return
                }

                self.viewModel.appearance.accentHex = hex

            }
        )

    }

    var body: some View {

        Form {

            Section("A workspace that feels like you") {

                HStack(spacing: 16) {

                    themePreview(.porcelain, background: "F6F8FA", sidebar: "E9ECF2", line: "BAA5DC")
                    themePreview(.safira, background: "161D26", sidebar: "0F1922", line: "968DCB")

                }
                .padding(.vertical, 10)

                Picker("Appearance", selection: self.$viewModel.appearance.theme) {
                    ForEach(ThemeSelection.allCases) { Text($0.rawValue).tag($0) }
                }

            }

            Section("Accent") {

                HStack(spacing: 16) {

                    ForEach(self.accents, id: \.self) { hex in

                        Button { self.viewModel.appearance.accentHex = hex } label: {

                            Circle().fill(Color(hex: hex)).frame(width: 25, height: 25)
                                .overlay {

                                    if self.viewModel.appearance.accentHex == hex {

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                            .transition(.scale.animation(.bouncy))

                                    }

                                }

                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Accent \(hex)")

                    }

                }
                .padding(.vertical, 5)

                ColorPicker("Custom color", selection: self.customAccentColor, supportsOpacity: false)

            }

            Section("Workspace") {

                Slider(value: self.$viewModel.appearance.sidebarWidth, in: 214...320, step: 1) {
                    Text("Sidebar width · \(Int(self.viewModel.appearance.sidebarWidth))")
                }

                Text("Changes apply to the current workspace immediately. Minimum width: 214 pt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Button("Reset appearance") { self.viewModel.resetAppearance() }

        }
        .formStyle(.grouped)
        .animation(.bouncy, value: self.viewModel.appearance.accentHex)

    }

    private func themePreview(_ selection: ThemeSelection, background: String, sidebar: String, line: String) -> some View {

        Button { self.viewModel.appearance.theme = selection } label: {

            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 0) {

                    Color(hex: sidebar).frame(width: 42)

                    VStack(alignment: .leading, spacing: 7) {

                        ForEach(0..<5) { index in

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: line).opacity(index == 2 ? 0.8 : 0.35))
                                .frame(width: CGFloat([84, 104, 68, 96, 54][index]), height: 4)

                        }

                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                }
                .frame(height: 100)
                .background(Color(hex: background))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.viewModel.appearance.theme == selection ? self.theme.accent : self.theme.border, lineWidth: 2))

                Text(selection.rawValue).font(.system(size: 11, weight: .medium))

            }
            .frame(maxWidth: .infinity)

        }
        .buttonStyle(.plain)

    }

}

#Preview {

    AppearanceSettingsScreen()
    .withMockPreviews()

}
