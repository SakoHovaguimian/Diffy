import Foundation

/// A user-selected local folder. The bookmark grants sandboxed access across launches;
/// the path is kept only for display and for recovering migrated records.
struct LocalCheckoutReference: Codable, Hashable, Sendable {
    var bookmarkData: Data?
    var lastKnownPath: String

    var displayPath: String {
        (self.lastKnownPath as NSString).abbreviatingWithTildeInPath
    }

    var folderName: String {
        (self.lastKnownPath as NSString).lastPathComponent
    }

    var hasBookmark: Bool {
        self.bookmarkData != nil
    }
}
