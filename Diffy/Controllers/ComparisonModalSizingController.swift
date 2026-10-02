import AppKit

/// Makes comparison sheets fill their owning workspace while retaining native modality.
@MainActor
final class ComparisonModalSizingController {

    private weak var sheet: NSWindow?
    private weak var parent: NSWindow?
    private var fillsWorkspace = false

    func attach(to sheet: NSWindow?, fillsWorkspace: Bool = false) {

        guard let sheet else { return }

        if self.sheet !== sheet {

            NotificationCenter.default.removeObserver(self)
            self.sheet = sheet
            self.parent = nil
            sheet.styleMask.insert(.resizable)
            sheet.minSize = NSSize(width: 720, height: 480)
            NotificationCenter.default.addObserver(self, selector: #selector(sheetWillBegin), name: NSWindow.willBeginSheetNotification, object: nil)

        }

        self.fillsWorkspace = fillsWorkspace
        guard let parent = sheet.sheetParent ?? sheet.parent else { return }

        if self.parent !== parent {

            if let previousParent = self.parent {
                NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: previousParent)
            }

            self.parent = parent
            NotificationCenter.default.addObserver(self, selector: #selector(resize), name: NSWindow.didResizeNotification, object: parent)

        }

        resize()

    }

    @objc private func sheetWillBegin() {

        DispatchQueue.main.async { [weak self] in

            guard let self, let sheet = self.sheet, sheet.sheetParent != nil else { return }
            self.attach(to: sheet, fillsWorkspace: self.fillsWorkspace)

        }

    }

    @objc private func resize() {

        guard let sheet, let parent = sheet.sheetParent ?? sheet.parent else { return }
        let available = parent.contentLayoutRect.size
        guard available.width.isFinite, available.height.isFinite,
              available.width > 0, available.height > 0 else { return }
        let screen = parent.screen?.visibleFrame.size ?? available
        let proposed = self.fillsWorkspace
            ? available
            : NSSize(width: min(available.width - 24, screen.width - 40), height: min(available.height - 24, screen.height - 80))
        let size = NSSize(width: max(720, proposed.width), height: max(480, proposed.height))
        let current = sheet.contentView?.bounds.size ?? .zero

        guard abs(current.width - size.width) > 1 || abs(current.height - size.height) > 1 else { return }
        sheet.setContentSize(size)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
