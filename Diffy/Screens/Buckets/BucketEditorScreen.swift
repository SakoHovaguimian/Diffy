import SwiftUI

struct BucketEditorScreen: View {

    @State var bucket: Bucket
    let save: (Bucket) -> Void
    let delete: ((Bucket) -> Void)?
    let replacementBucketName: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme
    @State private var showsDeleteConfirmation = false

    private let accents = ["7862D9", "319B90", "D39553", "CD7293", "548FC5", "7C9D5B"]
    private let symbols = ["folder", "square.stack.3d.up", "server.rack", "sparkles", "leaf", "hammer", "moon.stars", "heart"]

    private var customColor: Binding<Color> {

        Binding(
            get: { Color(hex: self.bucket.accentHex) },
            set: { color in

                guard let hex = color.rgbHex else {
                    return
                }

                self.bucket.accentHex = hex

            }
        )

    }

    var body: some View {

        VStack(alignment: .leading, spacing: 22) {

            Text("Make it yours.")
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.6)
            Text("A little identity for the work that belongs together.")
                .font(.system(size: 12))
                .foregroundStyle(self.theme.secondaryText)

            HStack(alignment: .top, spacing: 28) {

                fields().frame(width: 300)
                preview().frame(width: 220)

            }

            HStack {

                if self.delete != nil, self.replacementBucketName != nil {

                    Button("Delete Bucket", role: .destructive) {
                        self.showsDeleteConfirmation = true
                    }

                }

                Button("Reset style") {

                    self.bucket.accentHex = "7862D9"
                    self.bucket.symbol = "folder"

                }

                Spacer()
                Button("Cancel") { self.dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save Bucket") {

                    self.save(self.bucket)
                    self.dismiss()

                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(self.bucket.title.trimmingCharacters(in: .whitespaces).isEmpty)

            }

        }
        .padding(30)
        .background(self.theme.background)
        .confirmationDialog("Delete \(self.bucket.title)?", isPresented: self.$showsDeleteConfirmation) {

            Button("Delete Bucket", role: .destructive) {

                self.delete?(self.bucket)
                self.dismiss()

            }

        } message: {
            Text("Projects in this Bucket will move to \(self.replacementBucketName ?? "another Bucket"). Review notes and project files stay in place.")
        }

    }

    private func fields() -> some View {

        VStack(alignment: .leading, spacing: 16) {

            TextField("Bucket name", text: self.$bucket.title)

            HStack(spacing: 8) {

                ForEach(self.symbols, id: \.self) { symbol in

                    Button { self.bucket.symbol = symbol } label: {

                        Image(systemName: symbol)
                            .frame(width: 28, height: 28)
                            .foregroundStyle(self.bucket.symbol == symbol ? self.theme.accent : self.theme.secondaryText)
                            .background(self.bucket.symbol == symbol ? self.theme.selection : .clear, in: RoundedRectangle(cornerRadius: 5))

                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(symbol)

                }

            }

            HStack(spacing: 12) {

                ForEach(self.accents, id: \.self) { hex in

                    Button { self.bucket.accentHex = hex } label: {

                        Circle().fill(Color(hex: hex)).frame(width: 24, height: 24)
                            .overlay(Circle().stroke(self.theme.text.opacity(self.bucket.accentHex == hex ? 0.6 : 0), lineWidth: 2).padding(-3))

                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Accent \(hex)")

                }

            }
            .padding(.vertical, 5)

            ColorPicker("Custom color", selection: self.customColor, supportsOpacity: false)

        }
        .font(.system(size: 12))
        .textFieldStyle(.roundedBorder)

    }

    private func preview() -> some View {

        let accent = Color(hex: self.bucket.accentHex)

        return VStack(alignment: .leading, spacing: 18) {

            Text("LIVE PREVIEW")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(self.theme.secondaryText)

            VStack(alignment: .leading, spacing: 16) {

                Image(systemName: self.bucket.symbol).font(.system(size: 24)).foregroundStyle(accent)
                Text(self.bucket.title).font(.system(size: 20, weight: .semibold))
                Divider()
                Label("Your projects", systemImage: "folder").font(.system(size: 12))
                Label("Another good idea", systemImage: "sparkles").font(.system(size: 12))

            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {

                LinearGradient(colors: [accent.opacity(0.16), self.theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)

            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.25)))

        }

    }

}

#Preview {

    BucketEditorScreen(
        bucket: MockWorkspaceFixtures.buckets[0],
        save: { _ in },
        delete: nil,
        replacementBucketName: nil
    )
    .withMockPreviews()

}
