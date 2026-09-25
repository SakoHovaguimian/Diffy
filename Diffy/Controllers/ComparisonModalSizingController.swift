import AppKit

/// Makes comparison sheets fill their owning workspace while retaining native modality.
@MainActor
final class ComparisonModalSizingController {

    private weak var sheet: NSWindow?

    func attach(to sheet: NSWindow?) {

        guard let sheet else { return }

        if self.sheet !== sheet {

            NotificationCenter.default.removeObserver(self)
            self.sheet = sheet
            NotificationCenter.default.addObserver(self, selector: #selector(resize), name: NSWindow.didResizeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(resize), name: NSWindow.didBecomeKeyNotification, object: sheet)

        }

        resize()

    }

    @objc private func resize() {

        guard let sheet, let parent = sheet.sheetParent ?? sheet.parent else { return }
        let available = parent.contentLayoutRect.size
        let screen = parent.screen?.visibleFrame.size ?? available
        let size = NSSize(
            width: max(800, min(available.width - 24, screen.width - 40)),
            height: max(500, min(available.height - 24, screen.height - 80))
        )
        let current = sheet.contentView?.bounds.size ?? .zero

        guard abs(current.width - size.width) > 1 || abs(current.height - size.height) > 1 else { return }
        sheet.setContentSize(size)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
