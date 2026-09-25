import SwiftUI
import AppKit

struct ResizeCursorView: NSViewRepresentable {

    func makeNSView(context: Context) -> CursorView {
        CursorView()
    }

    func updateNSView(_ view: CursorView, context: Context) {}

    final class CursorView: NSView {

        override func resetCursorRects() {

            super.resetCursorRects()
            addCursorRect(bounds, cursor: .resizeLeftRight)

        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            // Leave mouse events to the SwiftUI resize gesture above this view.
            nil
        }

    }

}
