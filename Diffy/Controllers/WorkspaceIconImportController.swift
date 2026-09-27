import AppKit
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class WorkspaceIconImportController {

    func chooseIcon() async throws -> WorkspaceCustomIcon? {

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Icon"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        let thumbnailTask = Task.detached(priority: .userInitiated) {
            try Self.thumbnailData(at: url)
        }
        let data = try await withTaskCancellationHandler {
            try await thumbnailTask.value
        } onCancel: {
            thumbnailTask.cancel()
        }
        try Task.checkCancellation()

        return .image(data)

    }

    nonisolated private static func thumbnailData(at url: URL) throws -> Data {

        try Task.checkCancellation()
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 128,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        try Task.checkCancellation()
        return try pngData(for: thumbnail)

    }

    nonisolated private static func pngData(for image: CGImage) throws -> Data {

        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return data as Data

    }

}
