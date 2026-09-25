import AppKit

@MainActor
enum MockImageService {

    static func artwork(updated: Bool) -> NSImage {

        NSImage(
            size: NSSize(width: 600, height: 440),
            flipped: false
        ) { _ in

            drawSky(updated: updated)
            drawSun(updated: updated)
            drawMountains(updated: updated)
            drawCaption(updated: updated)

            return true

        }

    }

    private static func drawSky(updated: Bool) {

        let top = NSColor(red: updated ? 0.82 : 0.87, green: 0.82, blue: updated ? 0.89 : 0.77, alpha: 1)
        let bottom = NSColor(red: 0.98, green: 0.94, blue: 0.84, alpha: 1)
        let gradient = NSGradient(starting: bottom, ending: top)
        gradient?.draw(in: NSRect(x: 0, y: 0, width: 600, height: 440), angle: 90)

    }

    private static func drawSun(updated: Bool) {

        NSColor(red: 0.98, green: updated ? 0.71 : 0.77, blue: 0.52, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: updated ? 369 : 342, y: 215, width: 110, height: 110)).fill()

    }

    private static func drawMountains(updated: Bool) {

        for layer in 0..<3 {

            let path = NSBezierPath()
            let baseline = CGFloat(60 + layer * 35)
            path.move(to: NSPoint(x: 0, y: 0))
            path.line(to: NSPoint(x: 0, y: baseline + 100))
            path.curve(to: NSPoint(x: 600, y: baseline + 45), controlPoint1: NSPoint(x: 170, y: baseline + 230 - CGFloat(layer * 65)), controlPoint2: NSPoint(x: 370, y: baseline - 70))
            path.line(to: NSPoint(x: 600, y: 0))
            path.close()

            let tone = CGFloat(layer) * 0.085
            NSColor(red: 0.22 + tone, green: (updated ? 0.38 : 0.42) + tone, blue: 0.37 + tone, alpha: 1).setFill()
            path.fill()

        }

    }

    private static func drawCaption(updated: Bool) {

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left

        let title: NSString = updated ? "Find your quiet." : "Find your calm."
        title.draw(in: NSRect(x: 42, y: 346, width: 480, height: 48), withAttributes: [
            .font: NSFont.systemFont(ofSize: 34, weight: .light),
            .foregroundColor: NSColor(red: 0.2, green: 0.27, blue: 0.27, alpha: 1),
            .paragraphStyle: paragraph
        ])

        let subtitle: NSString = "A LITTLE SPACE TO BREATHE"
        subtitle.draw(at: NSPoint(x: 44, y: 324), withAttributes: [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .kern: 2,
            .foregroundColor: NSColor.darkGray
        ])

    }

    static func pixel(in image: NSImage, x: Int, y: Int) -> String {

        guard (0..<600).contains(x), (0..<440).contains(y),
              let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let color = bitmap.colorAt(x: x * bitmap.pixelsWide / 600, y: y * bitmap.pixelsHigh / 440)?.usingColorSpace(.deviceRGB) else {
            return "—"
        }

        return String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))

    }

}
