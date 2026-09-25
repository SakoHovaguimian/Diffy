import AppKit

@MainActor
final class ProjectDirectoryController {

    func chooseDirectory() -> URL? {

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Project Folder"
        panel.message = "Choose a folder to add to Diffy. Its contents will not be changed."

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url?.standardizedFileURL

    }

}
