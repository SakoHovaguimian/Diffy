import SwiftUI
import AppKit

struct ComparisonModalSizingView: NSViewRepresentable {

    func makeNSView(context: Context) -> AttachmentView {
        AttachmentView()
    }

    func updateNSView(_ view: AttachmentView, context: Context) {
        view.attach()
    }

    final class AttachmentView: NSView {

        private let controller = ComparisonModalSizingController()

        override func viewDidMoveToWindow() {

            super.viewDidMoveToWindow()
            attach()

        }

        func attach() {

            // SwiftUI attaches the sheet to its parent after installing the content view.
            DispatchQueue.main.async { [weak self] in
                self?.controller.attach(to: self?.window)
            }

        }

    }

}
