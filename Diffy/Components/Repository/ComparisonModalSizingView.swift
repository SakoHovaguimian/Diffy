import SwiftUI
import AppKit

struct ComparisonModalSizingView: NSViewRepresentable {

    var fillsWorkspace = false

    func makeNSView(context: Context) -> AttachmentView {

        let view = AttachmentView()
        view.fillsWorkspace = self.fillsWorkspace
        return view

    }

    func updateNSView(_ view: AttachmentView, context: Context) {

        view.fillsWorkspace = self.fillsWorkspace
        view.attach()

    }

    final class AttachmentView: NSView {

        private let controller = ComparisonModalSizingController()
        var fillsWorkspace = false

        override func viewDidMoveToWindow() {

            super.viewDidMoveToWindow()
            attach()

        }

        func attach() {

            // SwiftUI attaches the sheet to its parent after installing the content view.
            DispatchQueue.main.async { [weak self] in

                guard let self else { return }
                self.controller.attach(to: self.window, fillsWorkspace: self.fillsWorkspace)

            }

        }

    }

}
