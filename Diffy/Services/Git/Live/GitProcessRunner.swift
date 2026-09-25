import Foundation
import os

/// Each process runs off the main actor. Files drain both streams without pipe deadlocks.
struct GitProcessRunner: Sendable {

    let executable: String

    func run(
        _ arguments: [String],
        directory: URL,
        acceptsFailure: Bool = false,
        timeout: TimeInterval = 120
    ) async throws -> GitCommandOutput {

        let cancellation = OSAllocatedUnfairLock(initialState: false)

        return try await withTaskCancellationHandler {

            try await Task.detached(priority: .userInitiated) {
                try execute(arguments, directory: directory, acceptsFailure: acceptsFailure, timeout: timeout, cancellation: cancellation)
            }.value

        } onCancel: {
            cancellation.withLock { $0 = true }
        }

    }

    private func execute(
        _ arguments: [String],
        directory: URL,
        acceptsFailure: Bool,
        timeout: TimeInterval,
        cancellation: OSAllocatedUnfairLock<Bool>
    ) throws -> GitCommandOutput {

        let scratch = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: scratch) }

        let outputURL = scratch.appendingPathComponent("stdout")
        let errorURL = scratch.appendingPathComponent("stderr")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
        FileManager.default.createFile(atPath: errorURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
        let output = try FileHandle(forWritingTo: outputURL)
        let errors = try FileHandle(forWritingTo: errorURL)
        defer { try? output.close() }
        defer { try? errors.close() }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: self.executable)
        process.arguments = ["--no-pager", "--literal-pathspecs", "-c", "color.ui=false"] + arguments
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = errors
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["GIT_EDITOR"] = "/usr/bin/true"
        environment["GIT_SEQUENCE_EDITOR"] = "/usr/bin/true"
        environment["GIT_OPTIONAL_LOCKS"] = "0"
        environment["GIT_SSH_COMMAND"] = "ssh -o BatchMode=yes -o ConnectTimeout=20"
        environment["LC_ALL"] = "C"
        process.environment = environment

        guard !cancellation.withLock({ $0 }) else {
            throw CancellationError()
        }

        do {
            try process.run()
        } catch {
            throw GitError.executableUnavailable(error.localizedDescription)
        }

        let deadline = Date().addingTimeInterval(timeout)

        while process.isRunning {

            if cancellation.withLock({ $0 }) || Date() > deadline {

                process.terminate()
                Thread.sleep(forTimeInterval: 0.2)

                if process.isRunning {
                    kill(process.processIdentifier, SIGKILL)
                }

                process.waitUntilExit()

                if cancellation.withLock({ $0 }) {
                    throw CancellationError()
                }

                throw GitError.timedOut(subcommand: arguments.first ?? "")

            }

            Thread.sleep(forTimeInterval: 0.05)

        }

        process.waitUntilExit()
        let reader = try FileHandle(forReadingFrom: outputURL)
        defer { try? reader.close() }
        let data = try reader.read(upToCount: 8_000_001) ?? Data()

        guard data.count <= 8_000_000 else {
            throw GitError.unsupported("This result exceeds the 8 MB display limit. Select a smaller comparison or a single file.")
        }

        let errorReader = try FileHandle(forReadingFrom: errorURL)
        defer { try? errorReader.close() }
        let errorData = try errorReader.read(upToCount: 32_768) ?? Data()
        let message = Self.sanitize(String(decoding: errorData, as: UTF8.self))

        guard acceptsFailure || process.terminationStatus == 0 else {
            throw GitError.commandFailed(GitCommandFailure(subcommand: arguments.first ?? "", exitStatus: process.terminationStatus, message: message))
        }

        return GitCommandOutput(status: process.terminationStatus, data: data, error: message)

    }

    static func sanitize(_ text: String) -> String {

        text.replacingOccurrences(of: #"(https?://)[^\s/@]+@"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\b(gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b"#, with: "[redacted]", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)(authorization:\s*(?:bearer|basic)\s+)\S+"#, with: "$1[redacted]", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

    }

}
