import Foundation

@MainActor
final class DiffyMarkdownParser {

    static let shared = DiffyMarkdownParser()
    private let cache = NSCache<NSString, ParsedBlocks>()

    private init() {

        self.cache.countLimit = 256
        self.cache.totalCostLimit = 8 * 1024 * 1024

    }

    func blocks(for markdown: String) -> [DiffyMarkdownBlock] {

        let key = markdown as NSString
        if let cached = self.cache.object(forKey: key) { return cached.value }

        let blocks = DiffyMarkdownBlock.parse(markdown)
        let cost = (markdown.utf8.count + blocks.reduce(0) { $0 + $1.text.characters.count }) * 64
        self.cache.setObject(ParsedBlocks(blocks), forKey: key, cost: cost)
        return blocks

    }

    private final class ParsedBlocks: NSObject {

        let value: [DiffyMarkdownBlock]

        init(_ value: [DiffyMarkdownBlock]) {
            self.value = value
        }

    }

}
