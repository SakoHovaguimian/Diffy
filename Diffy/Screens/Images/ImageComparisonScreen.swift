import SwiftUI
import Combine

struct ImageComparisonScreen: View {

    let file: DiffFile
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
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

        VStack(alignment: .leading, spacing: self.contentSize.scaled(14)) {

            HStack {

                Label(self.file.name, systemImage: "photo")
                    .font(self.contentSize.font(size: 13, weight: .medium))
                Spacer()
                DiffyBadge(title: "600 × 440", color: self.theme.secondaryText)

            }

            Picker("Image comparison mode", selection: self.$mode) {
                ForEach(ImageComparisonMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)

        }
        .padding(self.contentSize.scaled(18))

    }

    private func artwork(available: CGSize) -> some View {

        let fittedWidth = min(
            available.width - self.contentSize.scaled(50),
            (available.height - self.contentSize.scaled(60)) * 600 / 440
        )
        let width = fittedWidth * self.zoom
        let height = width * 440 / 600

        return imageContent(width: width, height: height)
            .frame(width: width, height: height)
            .offset(self.offset)
            .shadow(
                color: .black.opacity(0.09),
                radius: self.contentSize.scaled(24),
                y: self.contentSize.scaled(12)
            )
            .contentShape(Rectangle())
            .gesture(artworkDragGesture(width: width))
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

    private func artworkDragGesture(width: CGFloat) -> some Gesture {

        DragGesture(minimumDistance: 0)
            .onChanged { value in

                if self.mode == .slider {

                    updateRevealAmount(for: value.location.x, width: width)
                    return

                }

                self.offset = CGSize(width: self.dragStart.width + value.translation.width, height: self.dragStart.height + value.translation.height)

            }
            .onEnded { _ in

                guard self.mode != .slider else {
                    return
                }

                self.dragStart = self.offset

            }

    }

    private func updateRevealAmount(for horizontalPosition: CGFloat, width: CGFloat) {

        guard width > 0 else {
            return
        }

        self.amount = min(1, max(0, horizontalPosition / width))

    }

    @ViewBuilder
    private func imageContent(width: CGFloat, height: CGFloat) -> some View {

        switch self.mode {

        case .sideBySide:

            HStack(spacing: self.contentSize.scaled(12)) {

                VStack(spacing: self.contentSize.scaled(10)) {

                    image(self.original)
                    Text("Original").font(.caption).foregroundStyle(self.theme.secondaryText)

                }

                VStack(spacing: self.contentSize.scaled(10)) {

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

                Rectangle().fill(.white).frame(width: self.contentSize.scaled(2))
                    .offset(x: width * self.amount)

                Image(systemName: "arrow.left.and.right")
                    .font(self.contentSize.font(size: 12, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
                    .frame(width: self.contentSize.scaled(32), height: self.contentSize.scaled(32))
                    .background(.white, in: Circle())
                    .position(x: width * self.amount, y: height / 2)

            }

        }

    }

    private func image(_ image: NSImage) -> some View {
        Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
    }

    private func controls() -> some View {

        VStack(spacing: self.contentSize.scaled(14)) {

            HStack(spacing: self.contentSize.scaled(12)) {

                if self.mode == .slider || self.mode == .overlay {

                    Text(self.mode == .slider ? "Reveal" : "Opacity")
                    Slider(value: self.$amount, in: 0...1).frame(maxWidth: self.contentSize.scaled(180))

                }

                if self.mode == .blink && self.reduceMotion {
                    Button("Toggle frame") { self.blinkUpdated.toggle() }
                }

                Spacer()
                Button { updateZoom(self.zoom - 0.25) } label: { Image(systemName: "minus.magnifyingglass") }
                    .help("Zoom out")
                Text("\(Int(self.zoom * 100))%")
                    .monospacedDigit()
                    .frame(width: self.contentSize.scaled(40))
                Button { updateZoom(self.zoom + 0.25) } label: { Image(systemName: "plus.magnifyingglass") }
                    .help("Zoom in")
                Button("Fit") {

                    withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.24)) {

                        self.zoom = 1
                        self.offset = .zero
                        self.dragStart = .zero

                    }

                }

            }
            .font(self.contentSize.font(size: 11))
            .buttonStyle(.plain)

            Text(self.pixelDescription)
                .font(self.contentSize.font(size: 9, design: .monospaced))
                .foregroundStyle(self.theme.secondaryText)

        }
        .padding(self.contentSize.scaled(18))

    }

    private func updateZoom(_ proposedZoom: Double) {

        withAnimation(self.reduceMotion ? nil : .easeInOut(duration: 0.24)) {
            self.zoom = min(4, max(0.5, proposedZoom))
        }

    }

}

#Preview {

    ImageComparisonScreen(
        file: MockPreviewFixtures.imageFile
    )
    .frame(width: 950, height: 720)
    .withMockPreviews()

}
