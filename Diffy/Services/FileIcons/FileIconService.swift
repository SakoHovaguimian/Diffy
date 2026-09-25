import AppKit

@MainActor
final class FileIconService: FileIconServiceProtocol {

    private let bundle: Bundle
    private var catalogs: [FileIconTheme: FileIconCatalog] = [:]
    private var unavailableCatalogs: Set<FileIconTheme> = []
    private let images = NSCache<NSString, NSImage>()

    init(bundle: Bundle = .main) {

        self.bundle = bundle
        self.images.countLimit = 512

    }

    // MARK: - Bundled Icons

    func image(
        for path: String,
        isFolder: Bool,
        isExpanded: Bool,
        theme: FileIconTheme,
        isDark: Bool
    ) -> NSImage? {

        guard theme != .native, let catalog = catalog(for: theme) else {
            return nil
        }

        let associations = isDark ? catalog.dark : catalog.light
        let icon = associations.icon(for: path, isFolder: isFolder, isExpanded: isExpanded)
        let cacheKey = "\(theme.rawValue)/\(icon)" as NSString

        if let image = self.images.object(forKey: cacheKey) {
            return image
        }

        guard let url = self.bundle.url(forResource: icon, withExtension: "png", subdirectory: "FileIcons/\(theme.rawValue)"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = false
        self.images.setObject(image, forKey: cacheKey)
        return image

    }

    private func catalog(for theme: FileIconTheme) -> FileIconCatalog? {

        if let catalog = self.catalogs[theme] {
            return catalog
        }

        guard !self.unavailableCatalogs.contains(theme) else {
            return nil
        }

        guard let url = self.bundle.url(forResource: "catalog", withExtension: "json", subdirectory: "FileIcons/\(theme.rawValue)"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(FileIconCatalog.self, from: data) else {

            self.unavailableCatalogs.insert(theme)
            return nil

        }

        self.catalogs[theme] = catalog
        return catalog

    }

}
