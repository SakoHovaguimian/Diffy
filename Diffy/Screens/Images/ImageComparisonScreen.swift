import SwiftUI
import Combine

struct ImageComparisonScreen: View {

    let file: DiffFile
    @Environment(\.diffyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: ImageComparisonMode = .sideBySide
    @State private var amount = 0.5
    @State private var zoom = 1.0
    @State private var offset = CGSize.zero
    @State private var dragStart = CGSize.zero
    @State private var blinkUpdated = false
    @State private var pixelDescription = "Hover over the image to inspect a pixel"
    @State private var original = MockImageService.artwork(updated: false)
    @State private var updated = MockImageService.artwork(updated: true)
    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {

        VStack(spacing: 0) {

            header()

            GeometryReader { geometry in

                ZStack {

                    self.theme.elevated
                    artwork(available: geometry.size)

                }
                .clipped()

            }

            controls()

        }
        .background(self.theme.surface)
        .onReceive(self.timer) { _ in

            if self.mode == .blink && !self.reduceMotion {
                self.blinkUpdated.toggle()
            }

        }

    }

    private func header() -> some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack {

                Label(self.file.name, systemImage: "photo")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                DiffyBadge(title: "600 × 440", color: self.theme.secondaryText)

            }

            Picker("Image comparison mode", selection: self.$mode) {
                ForEach(ImageComparisonMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)

        }
        .padding(18)

    }

    private func artwork(available: CGSize) -> some View {

        let width = min(available.width - 50, (available.height - 60) * 600 / 440)
        let height = width * 440 / 600

        return imageContent(width: width, height: height)
            .frame(width: width, height: height)
            .scaleEffect(self.zoom)
            .offset(self.offset)
            .shadow(color: .black.opacity(0.09), radius: 24, y: 12)
            .gesture(DragGesture().onChanged { value in

                self.offset = CGSize(width: self.dragStart.width + value.translation.width, height: self.dragStart.height + value.translation.height)

            }.onEnded { _ in self.dragStart = self.offset })
            .onContinuousHover { phase in

                if case .active(let point) = phase {

                    guard self.mode != .sideBySide else {

                        self.pixelDescription = "Choose a single-canvas mode to inspect source pixels"
                        return

                    }

                    let x = Int(point.x / width * 600)
                    let y = Int(point.y / height * 440)
                    let left = MockImageService.pixel(in: self.original, x: x, y: y)
                    let right = MockImageService.pixel(in: self.updated, x: x, y: y)
                    self.pixelDescription = "x: \(x)  y: \(y)    Original \(left)    Updated \(right)"

                }

            }

    }

    @ViewBuilder
    private func imageContent(width: CGFloat, height: CGFloat) -> some View {

        switch self.mode {

        case .sideBySide:

            HStack(spacing: 12) {

                VStack(spacing: 10) {

                    image(self.original)
                    Text("Original").font(.caption).foregroundStyle(self.theme.secondaryText)

                }

                VStack(spacing: 10) {

                    image(self.updated)
                    Text("Updated").font(.caption).foregroundStyle(self.theme.secondaryText)

                }

            }

        case .overlay:

            ZStack {

                image(self.original)
                image(self.updated).opacity(self.amount)

            }

        case .difference:

            ZStack {

                image(self.original)
                image(self.updated).blendMode(.difference)

            }
            .compositingGroup()

        case .blink:
            image(self.blinkUpdated ? self.updated : self.original)

        case .slider:

            ZStack(alignment: .leading) {

                image(self.original)
                image(self.updated)
                    .mask(alignment: .leading) { Rectangle().frame(width: width * self.amount) }

                Rectangle().fill(.white).frame(width: 2)
                    .offset(x: width * self.amount)

                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(.white, in: Circle())
                    .position(x: width * self.amount, y: height / 2)

            }

        }

    }

    private func image(_ image: NSImage) -> some View {
        Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
    }

    private func controls() -> some View {

        VStack(spacing: 14) {

            HStack(spacing: 12) {

                if self.mode == .slider || self.mode == .overlay {

                    Text(self.mode == .slider ? "Reveal" : "Opacity")
                    Slider(value: self.$amount, in: 0...1).frame(maxWidth: 180)

                }

                if self.mode == .blink && self.reduceMotion {
                    Button("Toggle frame") { self.blinkUpdated.toggle() }
                }

                Spacer()
                Button { self.zoom = max(0.5, self.zoom - 0.25) } label: { Image(systemName: "minus.magnifyingglass") }
                    .help("Zoom out")
                Text("\(Int(self.zoom * 100))%").monospacedDigit().frame(width: 40)
                Button { self.zoom = min(4, self.zoom + 0.25) } label: { Image(systemName: "plus.magnifyingglass") }
                    .help("Zoom in")
                Button("Fit") {

                    self.zoom = 1
                    self.offset = .zero
                    self.dragStart = .zero

                }

            }
            .font(.system(size: 11))
            .buttonStyle(.plain)

            Text(self.pixelDescription)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(self.theme.secondaryText)

        }
        .padding(18)

    }

}

#Preview {

    ImageComparisonScreen(
        file: MockPreviewFixtures.imageFile
    )
    .frame(width: 950, height: 720)
    .withMockPreviews()

}
