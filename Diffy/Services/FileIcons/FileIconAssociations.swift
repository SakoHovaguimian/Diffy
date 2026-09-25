import Foundation

struct FileIconAssociations: Decodable {

    let file: String
    let folder: String
    let folderExpanded: String
    let fileNames: [String: String]
    let fileExtensions: [String: String]
    let folderNames: [String: String]
    let folderNamesExpanded: [String: String]

    func icon(for path: String, isFolder: Bool, isExpanded: Bool) -> String {

        let normalizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let name = (normalizedPath as NSString).lastPathComponent

        if isFolder {
            return isExpanded ? self.folderNamesExpanded[name] ?? self.folderExpanded : self.folderNames[name] ?? self.folder
        }

        return namedIcon(for: normalizedPath) ?? prefixedIcon(for: name) ?? extensionIcon(for: name) ?? self.file

    }

    // MARK: - File Matching

    private func namedIcon(for path: String) -> String? {

        var candidate = path

        while !candidate.isEmpty {

            if let icon = self.fileNames[candidate] {
                return icon
            }

            guard let separator = candidate.firstIndex(of: "/") else {
                break
            }

            candidate = String(candidate[candidate.index(after: separator)...])

        }

        return nil

    }

    private func extensionIcon(for name: String) -> String? {

        var candidate = name

        while let separator = candidate.firstIndex(of: ".") {

            candidate = String(candidate[candidate.index(after: separator)...])

            if let icon = self.fileExtensions[candidate] {
                return icon
            }

        }

        return nil

    }

    private func prefixedIcon(for name: String) -> String? {

        if name.hasPrefix("dockerfile.") || name.hasPrefix("containerfile.") {
            return self.fileNames["dockerfile"] ?? self.fileExtensions["dockerfile"]
        }

        if name.hasPrefix(".env.") {
            return self.fileNames[".env"] ?? self.fileExtensions["env"]
        }

        return nil

    }

}
