import Foundation
import os

/// Resolves security-scoped bookmarks and balances `startAccessingSecurityScopedResource`
/// with `stopAccessingSecurityScopedResource`. Access is reference counted per project so
/// a long-lived watcher and short Git commands can overlap safely.
final class SecurityScopedAccessController: Sendable {

    private struct Session {
        let url: URL
        let startedSecurityScope: Bool
        var count: Int
    }

    private let sessions = OSAllocatedUnfairLock(initialState: [String: Session]())

    // MARK: - Bookmarks

    func makeBookmark(for directoryURL: URL) throws -> Data {

        try directoryURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

    }

    /// Resolves a checkout. A stale bookmark still resolves; the returned reference carries
    /// a renewed bookmark that the caller should persist.
    func resolve(_ checkout: LocalCheckoutReference) throws -> (url: URL, renewedCheckout: LocalCheckoutReference?) {

        guard let bookmarkData = checkout.bookmarkData else {
            return (try resolveUnbookmarkedPath(checkout.lastKnownPath), nil)
        }

        var isStale = false
        let url: URL

        do {

            url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

        } catch {
            throw GitError.checkoutUnavailable(.folderMissing)
        }

        let renewed = isStale ? renewedCheckout(for: url) : nil
        return (url, renewed)

    }

    // MARK: - Access Sessions

    @discardableResult
    func beginAccess(projectID: String, checkout: LocalCheckoutReference) throws -> URL {

        if let existingURL = incrementExistingSession(projectID: projectID) {
            return existingURL
        }

        let resolved = try resolve(checkout)
        let startedSecurityScope = resolved.url.startAccessingSecurityScopedResource()

        guard startedSecurityScope || checkout.bookmarkData == nil else {
            throw GitError.checkoutUnavailable(.accessDenied)
        }

        return storeSession(
            projectID: projectID,
            url: resolved.url,
            startedSecurityScope: startedSecurityScope
        )

    }

    func endAccess(projectID: String) {

        let finishedSession = self.sessions.withLock { sessions -> Session? in

            guard var session = sessions[projectID] else {
                return nil
            }

            session.count -= 1

            if session.count > 0 {

                sessions[projectID] = session
                return nil

            }

            sessions[projectID] = nil
            return session

        }

        if let finishedSession, finishedSession.startedSecurityScope {
            finishedSession.url.stopAccessingSecurityScopedResource()
        }

    }

    func withAccess<Value: Sendable>(
        projectID: String,
        checkout: LocalCheckoutReference,
        _ body: (URL) async throws -> Value
    ) async throws -> Value {

        let url = try beginAccess(projectID: projectID, checkout: checkout)

        defer {
            endAccess(projectID: projectID)
        }

        return try await body(url)

    }

    // MARK: - Helpers

    private func incrementExistingSession(projectID: String) -> URL? {

        self.sessions.withLock { sessions in

            guard var session = sessions[projectID] else {
                return nil
            }

            session.count += 1
            sessions[projectID] = session

            return session.url

        }

    }

    private func storeSession(
        projectID: String,
        url: URL,
        startedSecurityScope: Bool
    ) -> URL {

        let redundantSession = self.sessions.withLock { sessions -> Bool in

            if var existing = sessions[projectID] {

                existing.count += 1
                sessions[projectID] = existing
                return true

            }

            sessions[projectID] = Session(url: url, startedSecurityScope: startedSecurityScope, count: 1)
            return false

        }

        if redundantSession, startedSecurityScope {
            url.stopAccessingSecurityScopedResource()
        }

        return url

    }

    /// Records migrated from Milestone 0 have only a path. Outside the sandbox the path may
    /// still be readable; inside it, the user must locate the folder once.
    private func resolveUnbookmarkedPath(_ path: String) throws -> URL {

        let url = URL(fileURLWithPath: path, isDirectory: true)

        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw GitError.checkoutUnavailable(.missingBookmark)
        }

        return url

    }

    private func renewedCheckout(for url: URL) -> LocalCheckoutReference? {

        let startedSecurityScope = url.startAccessingSecurityScopedResource()

        defer {

            if startedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }

        }

        guard let bookmarkData = try? makeBookmark(for: url) else {
            return nil
        }

        return LocalCheckoutReference(bookmarkData: bookmarkData, lastKnownPath: url.path)

    }

}
