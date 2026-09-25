import AppKit
import UniformTypeIdentifiers

@MainActor
enum ExportController {

    @discardableResult
    static func copy(_ text: String) -> Bool {

        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(text, forType: .string)

    }

    static func saveMarkdown(_ text: String, completion: @escaping (String) -> Void) {

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Diffy Review.md"
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.canCreateDirectories = true

        panel.begin { response in

            guard response == .OK, let url = panel.url else {
                return
            }

            do {

                try text.write(to: url, atomically: true, encoding: .utf8)
                completion("Saved \(url.lastPathComponent)")

            } catch {
                completion("Could not save: \(error.localizedDescription)")
            }

        }

    }

}
