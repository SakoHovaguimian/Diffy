import Foundation
import Darwin
import os

/// Runs a single read-only CLI control request without sending a generation prompt.
struct AIControlRequestRunner: Sendable {

    struct Exchange: Sendable {
        let request: Data
        let responseID: String
    }

    func run(
        executable: URL,
        arguments: [String],
        request: Data,
        requestID: String,
        directory: URL,
        environment: [String: String],
        timeout: TimeInterval = 25
    ) async throws -> Data {

        try await self.run(
            executable: executable,
            arguments: arguments,
            exchanges: [Exchange(request: request, responseID: requestID)],
            directory: directory,
            environment: environment,
            timeout: timeout
        )

    }

    func run(
        executable: URL,
        arguments: [String],
        exchanges: [Exchange],
        directory: URL,
        environment: [String: String],
        timeout: TimeInterval = 25
    ) async throws -> Data {

        let cancellation = OSAllocatedUnfairLock(initialState: false)

        return try await withTaskCancellationHandler {
            try await Task.detached(priority: .userInitiated) {
                try self.execute(
                    executable: executable,
                    arguments: arguments,
                    exchanges: exchanges,
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
        exchanges: [Exchange],
        directory: URL,
        environment: [String: String],
        timeout: TimeInterval,
        cancellation: OSAllocatedUnfairLock<Bool>
    ) throws -> Data {

        let outputURL = directory.appendingPathComponent("catalog-output")
        let errorURL = directory.appendingPathComponent("catalog-error")
        let writer = AICommandRunner()
        try writer.writePrivate(Data(), to: outputURL)
        try writer.writePrivate(Data(), to: errorURL)
        defer { try? FileManager.default.removeItem(at: outputURL) }
        defer { try? FileManager.default.removeItem(at: errorURL) }

        let outputHandle = try FileHandle(forWritingTo: outputURL)
        let errorHandle = try FileHandle(forWritingTo: errorURL)
        defer { try? outputHandle.close() }
        defer { try? errorHandle.close() }

        let input = Pipe()
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = environment
        process.standardInput = input
        process.standardOutput = outputHandle
        process.standardError = errorHandle

        guard !cancellation.withLock({ $0 }) else { throw CancellationError() }

        do {
            try process.run()
        } catch {
            throw AICommandError.unavailable(executable.lastPathComponent)
        }

        defer {
            try? input.fileHandleForWriting.close()
            self.stop(process)
        }

        let deadline = Date().addingTimeInterval(timeout)

        var finalResponse = Data()
        for (index, exchange) in exchanges.enumerated() {

            try input.fileHandleForWriting.write(contentsOf: exchange.request)
            finalResponse = try self.waitForResponse(
                requestID: exchange.responseID,
                outputURL: outputURL,
                errorURL: errorURL,
                process: process,
                deadline: deadline,
                cancellation: cancellation
            )

            if index < exchanges.count - 1,
               let message = try? JSONSerialization.jsonObject(with: finalResponse) as? [String: Any],
               message["error"] != nil {
                throw AIReviewError.unavailable("The installed tool rejected model catalog initialization. Check sign-in or update the tool.")
            }

        }

        return finalResponse

    }

    private func waitForResponse(
        requestID: String,
        outputURL: URL,
        errorURL: URL,
        process: Process,
        deadline: Date,
        cancellation: OSAllocatedUnfairLock<Bool>
    ) throws -> Data {

        while Date() < deadline {

            if cancellation.withLock({ $0 }) { throw CancellationError() }
            let size = try outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            let errorSize = try errorURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 1_000_000, errorSize <= 1_000_000 else {
                throw AICommandError.oversizedOutput
            }

            let output = try Data(contentsOf: outputURL)
            if let response = self.response(in: output, requestID: requestID) {
                return response
            }

            if !process.isRunning {

                let errorData = try Data(contentsOf: errorURL)
                let detail = AICommandDiagnostics.message(
                    standardError: Data(errorData.suffix(65_536)),
                    standardOutput: output
                )
                throw AICommandError.failed(
                    name: process.executableURL?.lastPathComponent ?? "Installed AI tool",
                    exitStatus: process.terminationStatus,
                    detail: detail
                )

            }

            Thread.sleep(forTimeInterval: 0.05)

        }

        throw AIReviewError.unavailable("The installed tool did not return a model catalog in time. Retry or choose another route.")

    }

    private func response(in output: Data, requestID: String) -> Data? {

        for line in output.split(separator: UInt8(ascii: "\n")) {

            let data = Data(line)
            guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  self.matches(message, requestID: requestID) else {
                continue
            }

            return data

        }

        return nil

    }

    private func matches(_ message: [String: Any], requestID: String) -> Bool {

        if message["type"] as? String == "control_response",
           let envelope = message["response"] as? [String: Any] {
            return envelope["request_id"] as? String == requestID
        }

        if message["jsonrpc"] as? String == "2.0" {
            return String(describing: message["id"] ?? "") == requestID
        }

        return false

    }

    private func stop(_ process: Process) {

        guard process.isRunning else { return }
        process.terminate()
        Thread.sleep(forTimeInterval: 0.2)
        if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        process.waitUntilExit()

    }
}
