import Foundation

struct GitCloneRequest: Hashable, Sendable {
    let remoteURL: String
    let parentDirectory: URL
    let directoryName: String

    var destination: URL {
        self.parentDirectory.appendingPathComponent(self.directoryName, isDirectory: true)
    }
}
