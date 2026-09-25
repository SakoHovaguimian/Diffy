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
    @State private var pixelDescription = "Hover Over The Image To Inspect A Pixel"
    private let original: NSImage?
    private let updated: NSImage?
    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    init(file: DiffFile, sources: ImageComparisonSources? = nil) {

        self.file = file

        if let sources {

            self.original = sources.original.flatMap(NSImage.init(data:))
            self.updated = sources.updated.flatMap(NSImage.init(data:))

        } else {

            self.original = MockImageService.artwork(updated: false)
            self.updated = MockImageService.artwork(updated: true)

        }

    }

    private var imageSize: CGSize {

        let image = self.updated ?? self.original
        let representation = image?.representations.first
        return CGSize(width: max(1, representation?.pixelsWide ?? 600), height: max(1, representation?.pixelsHigh ?? 440))

    }

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
                DiffyBadge(title: "\(Int(self.imageSize.width)) × \(Int(self.imageSize.height))", color: self.theme.secondaryText)

            }

            Picker("Image Comparison Mode", selection: self.$mode) {
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
            (available.height - self.contentSize.scaled(60)) * self.imageSize.width / self.imageSize.height
        )
        let width = max(1, fittedWidth) * self.zoom
        let height = width * self.imageSize.height / self.imageSize.width

        return imageContent(width: width, height: height)
            .frame(width: width, height: height)
            .geometryGroup()
            .compositingGroup()
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

                        self.pixelDescription = "Choose A Single-Canvas Mode To Inspect Source Pixels"
                        return

                    }

                    let x = Int(point.x / width * self.imageSize.width)
                    let y = Int(point.y / height * self.imageSize.height)
                    let left = self.original.map { MockImageService.pixel(in: $0, x: x, y: y) } ?? "Absent"
                    let right = self.updated.map { MockImageService.pixel(in: $0, x: x, y: y) } ?? "Absent"
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

    @ViewBuilder
    private func image(_ image: NSImage?) -> some View {

        if let image {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
        } else {
            DiffyEmptyState(symbol: "photo", title: "No Image", message: "This side has no displayable image.")
        }

    }

    private func controls() -> some View {

        VStack(spacing: self.contentSize.scaled(14)) {

            HStack(spacing: self.contentSize.scaled(12)) {

                if self.mode == .slider || self.mode == .overlay {

                    Text(self.mode == .slider ? "Reveal" : "Opacity")
                    Slider(value: self.$amount, in: 0...1).frame(maxWidth: self.contentSize.scaled(180))

                }

                if self.mode == .blink && self.reduceMotion {
                    Button("Toggle Frame") { self.blinkUpdated.toggle() }
                }

                Spacer()
                Button { updateZoom(self.zoom - 0.25) } label: { Image(systemName: "minus.magnifyingglass") }
                    .help("Zoom Out")
                Text("\(Int(self.zoom * 100))%")
                    .monospacedDigit()
                    .frame(width: self.contentSize.scaled(40))
                Button { updateZoom(self.zoom + 0.25) } label: { Image(systemName: "plus.magnifyingglass") }
                    .help("Zoom In")
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
