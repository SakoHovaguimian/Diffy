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

            Section("A Workspace That Feels Like You") {

                themePreview
                    .padding(.vertical, 10)

                Picker("Theme", selection: self.$viewModel.appearance.theme) {
                    ForEach(ThemeSelection.allCases) { Text($0.displayName).tag($0) }
                }

            }

            FileIconSettingsSection()

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

                ColorPicker("Custom Color", selection: self.customAccentColor, supportsOpacity: false)

            }

            Section("Workspace") {

                Slider(value: self.$viewModel.appearance.sidebarWidth, in: 214...320, step: 1) {
                    Text("Sidebar Width · \(Int(self.viewModel.appearance.sidebarWidth))")
                }

                Text("Changes apply to the current workspace immediately. Minimum width: 214 pt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

            Button("Reset Appearance") { self.viewModel.resetAppearance() }

        }
        .formStyle(.grouped)
        .animation(.bouncy, value: self.viewModel.appearance.accentHex)

    }

    private var themePreview: some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 0) {

                self.theme.sidebar.frame(width: 46)

                VStack(alignment: .leading, spacing: 8) {

                    HStack(spacing: 0) {
                        Text("let ").foregroundStyle(self.theme.keyword)
                        Text("result").foregroundStyle(self.theme.type)
                        Text(" = ").foregroundStyle(self.theme.text)
                        Text("\"Diffy\"").foregroundStyle(self.theme.string)
                    }

                    HStack(spacing: 0) {
                        Text("+ ").foregroundStyle(self.theme.added)
                        Text("Clear, readable changes").foregroundStyle(self.theme.text)
                    }

                    HStack(spacing: 0) {
                        Text("− ").foregroundStyle(self.theme.removed)
                        Text("Easy to scan diffs").foregroundStyle(self.theme.text)
                    }

                }
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            }
            .frame(height: 104)
            .background(self.theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(self.theme.border, lineWidth: 1))

            Text("Preview · \(self.viewModel.appearance.theme.displayName)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(self.theme.secondaryText)

        }
        .frame(maxWidth: .infinity, alignment: .leading)

    }

}

#Preview {

    AppearanceSettingsScreen()
    .withMockPreviews()

}
