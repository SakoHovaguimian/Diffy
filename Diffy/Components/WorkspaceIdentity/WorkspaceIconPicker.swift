import SwiftUI

struct WorkspaceIconPicker: View {

    @Binding var symbol: String
    @Binding var customIcon: WorkspaceCustomIcon?
    let symbols: [String]
    let accent: Color
    @StateObject private var viewModel = WorkspaceIconPickerViewModel()
    @Environment(\.diffyTheme) private var theme

    private var emojiSelection: Binding<String> {

        Binding(
            get: {

                if case let .emoji(emoji) = self.customIcon { return emoji }
                return ""

            },
            set: { value in

                let emoji = String(value.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1))
                self.customIcon = emoji.isEmpty ? nil : .emoji(emoji)

            }
        )

    }

    private var imageLayoutSelection: Binding<WorkspaceIconImageLayout> {

        Binding(
            get: { self.customIcon?.imageLayout ?? .fit },
            set: { layout in self.customIcon = self.customIcon?.withImageLayout(layout) }
        )

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {

                ForEach(self.symbols, id: \.self) { symbol in

                    let isSelected = self.customIcon == nil && self.symbol == symbol
                    Button {

                        self.symbol = symbol
                        self.customIcon = nil

                    } label: {

                        Image(systemName: symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(isSelected ? self.accent : self.theme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(isSelected ? self.accent.opacity(0.12) : self.theme.surface, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? self.accent : self.theme.border))

                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(symbol)

                }

            }

            HStack(spacing: 10) {

                TextField("Emoji", text: self.emojiSelection)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Custom Emoji Icon")
                Button("Choose Image…") {

                    Task {

                        if let icon = await self.viewModel.chooseIcon() {
                            self.customIcon = icon.withImageLayout(self.customIcon?.imageLayout ?? .fit)
                        }

                    }

                }
                if self.customIcon != nil {
                    Button("Reset") { self.customIcon = nil }
                }

            }
            .font(.system(size: 12))

            if self.viewModel.isImporting {
                DiffyLoadingState(title: "Importing Icon…")
            }

            if self.customIcon?.imageLayout != nil {

                HStack(spacing: 12) {

                    Text("Image Layout").font(.system(size: 12))
                    Picker("Image Layout", selection: self.imageLayoutSelection) {
                        ForEach(WorkspaceIconImageLayout.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 140)

                }

            }

            if let errorMessage = self.viewModel.errorMessage {
                DiffyStatusBanner(message: errorMessage, isError: true)
            }

        }
        .diffyStatusAnimation(value: self.viewModel.errorMessage)
        .disabled(self.viewModel.isImporting)
        .onChange(of: self.customIcon) { _, _ in self.viewModel.clearError() }

    }

}
