import AppKit

@MainActor
protocol FileIconServiceProtocol: AnyObject, Sendable {

    func image(
        for path: String,
        isFolder: Bool,
        isExpanded: Bool,
        theme: FileIconTheme,
        isDark: Bool
    ) -> NSImage?

}
