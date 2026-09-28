import CoreServices
import Foundation

final class LiveRepositoryChangeMonitor: RepositoryChangeMonitoring {

    private let access: SecurityScopedAccessController
    private var stream: FSEventStreamRef?
    private var reference: GitRepositoryReference?
    private var location: GitRepositoryLocation?
    private var onChange: (@Sendable () -> Void)?

    init(access: SecurityScopedAccessController) {
        self.access = access
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring(
        reference: GitRepositoryReference,
        location: GitRepositoryLocation,
        onChange: @escaping @Sendable () -> Void
    ) throws {

        if self.reference == reference, self.location == location, self.stream != nil {
            self.onChange = onChange
            return
        }

        stopMonitoring()
        try self.access.beginAccess(projectID: reference.projectID, checkout: reference.checkout)

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        let paths = Array(Set([
            location.rootPath,
            location.gitDirectoryPath,
            location.commonDirectoryPath
        ])) as CFArray
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, context, eventCount, eventPaths, _, _ in

                guard let context else { return }
                let monitor = Unmanaged<LiveRepositoryChangeMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.handleEvents(count: eventCount, paths: eventPaths)

            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.3,
            flags
        ) else {

            self.access.endAccess(projectID: reference.projectID)
            throw CocoaError(.fileReadUnknown)

        }

        FSEventStreamSetDispatchQueue(stream, .main)

        guard FSEventStreamStart(stream) else {

            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.access.endAccess(projectID: reference.projectID)
            throw CocoaError(.fileReadUnknown)

        }

        self.stream = stream
        self.reference = reference
        self.location = location
        self.onChange = onChange

    }

    func stopMonitoring() {

        if let stream = self.stream {

            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)

        }

        if let reference = self.reference {
            self.access.endAccess(projectID: reference.projectID)
        }

        self.stream = nil
        self.reference = nil
        self.location = nil
        self.onChange = nil

    }

    private func handleEvents(count: Int, paths: UnsafeMutableRawPointer) {

        guard let location else { return }
        let eventPaths = paths.assumingMemoryBound(to: UnsafePointer<CChar>.self)

        for index in 0..<count {

            let path = String(cString: eventPaths[index])

            if shouldRefresh(for: path, location: location) {

                self.onChange?()
                return

            }

        }

    }

    private func shouldRefresh(for path: String, location: GitRepositoryLocation) -> Bool {

        if path == location.gitDirectoryPath || path.hasPrefix(location.gitDirectoryPath + "/") {
            return isRelevantGitEvent(path, in: location.gitDirectoryPath)
        }

        if path == location.commonDirectoryPath || path.hasPrefix(location.commonDirectoryPath + "/") {
            return isRelevantGitEvent(path, in: location.commonDirectoryPath)
        }

        return path == location.rootPath || path.hasPrefix(location.rootPath + "/")

    }

    private func isRelevantGitEvent(_ path: String, in directory: String) -> Bool {

        let relativePath = String(path.dropFirst(directory.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let directNames: Set<String> = [
            "", "HEAD", "index", "packed-refs", "config", "MERGE_HEAD",
            "CHERRY_PICK_HEAD", "REVERT_HEAD", "REBASE_HEAD"
        ]

        return directNames.contains(relativePath)
            || relativePath.hasPrefix("refs/")
            || relativePath.hasPrefix("rebase-merge/")
            || relativePath.hasPrefix("rebase-apply/")

    }

}
