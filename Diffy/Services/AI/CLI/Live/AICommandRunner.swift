import Foundation
import Darwin
import os

/// Uses argument arrays and private files; prompts never appear in shell commands.
struct AICommandRunner: Sendable {

    func run(
        executable: URL,
        arguments: [String],
        input: Data,
        directory: URL,
        environment: [String: String],
        timeout: TimeInterval = 240
    ) async throws -> Data {

        let cancellation = OSAllocatedUnfairLock(initialState: false)

        return try await withTaskCancellationHandler {

            try await Task.detached(priority: .userInitiated) {

                try self.execute(
                    executable: executable,
                    arguments: arguments,
                    input: input,
                    directory: directory,
                    environment: environment,
                    timeout: timeout,
                    cancellation: cancellation
                )

            }.value

        } onCancel: {
            cancellation.withLock { $0 = true }
        }

    }

    private func execute(
        executable: URL,
        arguments: [String],
        input: Data,
        directory: URL,
        environment: [String: String],
        timeout: TimeInterval,
        cancellation: OSAllocatedUnfairLock<Bool>
    ) throws -> Data {

        let identifier = UUID().uuidString
        let inputURL = directory.appendingPathComponent("\(identifier)-input")
        let outputURL = directory.appendingPathComponent("\(identifier)-output")
        let errorURL = directory.appendingPathComponent("\(identifier)-error")
        try self.writePrivate(input, to: inputURL)
        try self.writePrivate(Data(), to: outputURL)
        try self.writePrivate(Data(), to: errorURL)
        defer { try? FileManager.default.removeItem(at: inputURL) }
        defer { try? FileManager.default.removeItem(at: outputURL) }
        defer { try? FileManager.default.removeItem(at: errorURL) }

        let inputHandle = try FileHandle(forReadingFrom: inputURL)
        let outputHandle = try FileHandle(forWritingTo: outputURL)
        let errorHandle = try FileHandle(forWritingTo: errorURL)
        defer { try? inputHandle.close() }
        defer { try? outputHandle.close() }
        defer { try? errorHandle.close() }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = environment
        process.standardInput = inputHandle
        process.standardOutput = outputHandle
        process.standardError = errorHandle

        guard !cancellation.withLock({ $0 }) else {
            throw CancellationError()
        }

        do {
            try process.run()
        } catch {
            throw AICommandError.unavailable(executable.lastPathComponent)
        }

        defer { self.stop(process) }
        let deadline = Date().addingTimeInterval(timeout)

        while process.isRunning {

            if cancellation.withLock({ $0 }) {
                throw CancellationError()
            }

            guard Date() < deadline else {
                throw AICommandError.timedOut
            }

            let size = try outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            let errorSize = try errorURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0

            guard size <= 4_000_000, errorSize <= 4_000_000 else {
                throw AICommandError.oversizedOutput
            }

            Thread.sleep(forTimeInterval: 0.05)

        }

        process.waitUntilExit()

        guard !cancellation.withLock({ $0 }) else {
            throw CancellationError()
        }

        let reader = try FileHandle(forReadingFrom: outputURL)
        defer { try? reader.close() }
        let data = try reader.read(upToCount: 4_000_001) ?? Data()

        guard data.count <= 4_000_000 else {
            throw AICommandError.oversizedOutput
        }

        guard process.terminationStatus == 0 else {

            let errors = try FileHandle(forReadingFrom: errorURL)
            defer { try? errors.close() }
            let errorSize = try errors.seekToEnd()
            try errors.seek(toOffset: errorSize > 65_536 ? errorSize - 65_536 : 0)
            let errorData = try errors.read(upToCount: 65_536) ?? Data()
            let detail = AICommandDiagnostics.message(standardError: errorData, standardOutput: data)
            throw AICommandError.failed(name: executable.lastPathComponent, exitStatus: process.terminationStatus, detail: detail)

        }

        return data

    }

    private func stop(_ process: Process) {

        guard process.isRunning else { return }
        process.terminate()
        Thread.sleep(forTimeInterval: 0.2)

        if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
        }

        process.waitUntilExit()

    }

    func writePrivate(_ data: Data, to url: URL) throws {

        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)

    }

}
