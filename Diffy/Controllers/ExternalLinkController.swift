import AppKit

@MainActor
struct ExternalLinkController {

    func open(_ url: URL) {

        guard url.scheme == "https" else { return }
        NSWorkspace.shared.open(url)

    }

    func copy(_ value: String) {

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)

    }

    func reveal(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

}
