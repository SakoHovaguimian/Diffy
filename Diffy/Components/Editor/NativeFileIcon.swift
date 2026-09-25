import Foundation

enum NativeFileIcon {

    static func symbol(for path: String, isFolder: Bool, isBinary: Bool) -> String {

        if isFolder {
            return "folder.fill"
        }

        switch (path as NSString).pathExtension.lowercased() {

        case "swift": return "swift"
        case "ts", "tsx", "js", "jsx", "py", "rb", "rs", "go", "c", "h", "cpp", "java", "kt":
            return "chevron.left.forwardslash.chevron.right"

        case "json", "jsonc", "yaml", "yml", "toml", "xml", "plist": return "curlybraces"
        case "png", "jpg", "jpeg", "webp", "gif", "svg", "ico", "heic", "avif": return "photo"
        case "woff", "woff2", "ttf", "otf": return "textformat"
        case "zip", "gz", "tar", "7z", "rar": return "doc.zipper"
        case "mp3", "wav", "aac", "flac": return "waveform"
        case "mp4", "mov", "webm": return "film"
        case "sh", "bash", "zsh", "fish": return "terminal"
        default: return isBinary ? "doc.zipper" : "doc.text"

        }

    }

}
