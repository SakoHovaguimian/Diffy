import AppKit

/// Makes comparison sheets fill their owning workspace while retaining native modality.
@MainActor
final class ComparisonModalSizingController {

    private weak var sheet: NSWindow?
    private weak var parent: NSWindow?

    func attach(to sheet: NSWindow?) {

        guard let sheet, let parent = sheet.sheetParent ?? sheet.parent else { return }

        if self.sheet !== sheet || self.parent !== parent {

            NotificationCenter.default.removeObserver(self)
            self.sheet = sheet
            self.parent = parent
            sheet.styleMask.insert(.resizable)
            sheet.minSize = NSSize(width: 720, height: 480)
            NotificationCenter.default.addObserver(self, selector: #selector(resize), name: NSWindow.didResizeNotification, object: parent)
            resize()

        }

    }

    @objc private func resize() {

        guard let sheet, let parent = sheet.sheetParent ?? sheet.parent else { return }
        let available = parent.contentLayoutRect.size
        let screen = parent.screen?.visibleFrame.size ?? available
        let size = NSSize(width: min(available.width - 24, screen.width - 40), height: min(available.height - 24, screen.height - 80))
        let current = sheet.contentView?.bounds.size ?? .zero

        guard abs(current.width - size.width) > 1 || abs(current.height - size.height) > 1 else { return }
        sheet.setContentSize(size)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
