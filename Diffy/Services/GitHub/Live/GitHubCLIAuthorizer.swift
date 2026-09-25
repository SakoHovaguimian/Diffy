import Foundation
import os
import Darwin

/// Uses the official installed CLI's own OAuth flow when this build has no App ID.
/// Auth output is kept in memory. CLI configuration is isolated and removed afterwards.
struct GitHubCLIAuthorizer: Sendable {

    func authorize(
        host: String,
        challenge: @escaping @Sendable (GitHubSignInChallenge) -> Void
    ) async throws -> GitHubCredential {

        let cancellation = OSAllocatedUnfairLock(initialState: false)

        return try await withTaskCancellationHandler {

            try await Task.detached(priority: .userInitiated) {

                let executable = try locateExecutable()
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("diffy-github-\(UUID().uuidString)")
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
                defer { try? FileManager.default.removeItem(at: directory) }
                let arguments = ["auth", "login", "--hostname", host, "--web", "--git-protocol", "https", "--skip-ssh-key"]
                _ = try run(executable, arguments: arguments, directory: directory, host: host, cancellation: cancellation, challenge: challenge)
                let token = try run(executable, arguments: ["auth", "token", "--hostname", host], directory: directory, host: host, cancellation: cancellation, challenge: nil)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard !token.isEmpty else {
                    throw GitHubError.invalidResponse("GitHub CLI did not return a credential. Try signing in again.")
                }

                return GitHubCredential(accessToken: token, expiresAt: nil, isPersonalToken: false)

            }.value

        } onCancel: {
            cancellation.withLock { $0 = true }
        }

    }

    private func locateExecutable() throws -> String {

        let candidates = ["/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh"]

        guard let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            throw GitHubError.forbidden("Install GitHub CLI from cli.github.com, then choose Sign in with GitHub again. You can also connect with a personal access token below.")
        }

        return path

    }

    private func run(
        _ executable: String,
        arguments: [String],
        directory: URL,
        host: String,
        cancellation: OSAllocatedUnfairLock<Bool>,
        challenge: (@Sendable (GitHubSignInChallenge) -> Void)?
    ) throws -> String {

        let process = Process()
        let output = Pipe()
        var captured = Data()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = challenge == nil ? FileHandle.nullDevice : output
        process.standardInput = FileHandle.nullDevice
        var environment = ProcessInfo.processInfo.environment

        for key in ["GH_TOKEN", "GITHUB_TOKEN", "GH_ENTERPRISE_TOKEN", "GITHUB_ENTERPRISE_TOKEN", "GH_DEBUG"] {
            environment[key] = nil
        }

        environment["GH_CONFIG_DIR"] = directory.path
        environment["GH_PROMPT_DISABLED"] = "1"
        environment["GH_BROWSER"] = "/usr/bin/true"
        environment["GH_NO_UPDATE_NOTIFIER"] = "1"
        environment["NO_COLOR"] = "1"
        process.environment = environment
        let descriptor = output.fileHandleForReading.fileDescriptor
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
        guard !cancellation.withLock({ $0 }) else { throw CancellationError() }
        try process.run()
        defer {

            if process.isRunning {

                process.terminate()
                Thread.sleep(forTimeInterval: 0.2)
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                process.waitUntilExit()

            }

        }
        let deadline = Date().addingTimeInterval(challenge == nil ? 30 : 900)
        var deliveredCode = false

        while process.isRunning {

            captured.append(readAvailable(output.fileHandleForReading))

            guard captured.count < 65_536 else {
                throw GitHubError.invalidResponse("GitHub CLI returned too much output. Try again.")
            }

            if cancellation.withLock({ $0 }) || Date() > deadline {

                process.terminate()
                Thread.sleep(forTimeInterval: 0.2)
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                process.waitUntilExit()
                if cancellation.withLock({ $0 }) { throw CancellationError() }
                throw GitHubError.authorizationExpired

            }

            if !deliveredCode, let challenge {

                let text = String(decoding: captured, as: UTF8.self)

                if let range = text.range(of: #"\b[A-Z0-9]{4}-[A-Z0-9]{4}\b"#, options: .regularExpression),
                   let url = URL(string: "https://\(host)/login/device") {

                    deliveredCode = true
                    challenge(GitHubSignInChallenge(userCode: String(text[range]), verificationURL: url, expiresAt: deadline, providerName: "GitHub CLI"))

                }

            }

            Thread.sleep(forTimeInterval: 0.05)

        }

        process.waitUntilExit()
        captured.append(readAvailable(output.fileHandleForReading))

        guard process.terminationStatus == 0 else {

            let message = challenge == nil ? "GitHub CLI could not read its credential." : GitProcessRunner.sanitize(String(decoding: captured, as: UTF8.self))
            throw GitHubError.forbidden(message.isEmpty ? "GitHub CLI sign-in failed. Try again." : message)

        }

        return String(decoding: captured, as: UTF8.self)

    }

    private func readAvailable(_ handle: FileHandle) -> Data {

        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)

        while result.count < 65_536 {

            let count = buffer.withUnsafeMutableBytes { bytes in
                Darwin.read(handle.fileDescriptor, bytes.baseAddress, bytes.count)
            }

            guard count > 0 else { break }
            result.append(contentsOf: buffer.prefix(count))

        }

        return result

    }

}
