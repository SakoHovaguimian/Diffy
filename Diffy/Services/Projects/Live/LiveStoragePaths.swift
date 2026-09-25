import Foundation

/// Every location Diffy Live writes. All of it is under Application Support; nothing is
/// ever written inside a user's repository.
struct LiveStoragePaths: Sendable {

    let root: URL

    static func standard() -> LiveStoragePaths {

        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        return LiveStoragePaths(root: applicationSupport.appendingPathComponent("Diffy", isDirectory: true))

    }

    // MARK: - Durable User Data

    /// Annotations keep their Milestone 0 location so existing review notes remain available.
    var annotationsFile: URL {
        self.root.appendingPathComponent("annotations-v1.json")
    }

    var projectsFile: URL {
        self.root.appendingPathComponent("Projects/projects-v2.json")
    }

    /// Non-secret account metadata. Tokens are stored only in the Keychain.
    var gitHubAccountsFile: URL {
        self.root.appendingPathComponent("Accounts/github-accounts-v1.json")
    }

    // MARK: - Live Data

    var liveDirectory: URL {
        self.root.appendingPathComponent("Live", isDirectory: true)
    }

    /// Disposable, versioned cache. Clear Cache removes only this directory.
    var cacheDirectory: URL {
        self.liveDirectory.appendingPathComponent("Cache-v1", isDirectory: true)
    }

    /// Recoverable merge drafts. Kept separate so clearing the cache never loses a draft.
    var mergeDraftsDirectory: URL {
        self.liveDirectory.appendingPathComponent("MergeDrafts-v1", isDirectory: true)
    }

    /// Scratch space for temporary merge inputs. Never inside a repository.
    var temporaryDirectory: URL {
        self.liveDirectory.appendingPathComponent("Temporary", isDirectory: true)
    }

}
