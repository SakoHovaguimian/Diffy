import CryptoKit
import Foundation

/// Each record is its own immutable, atomically written file. Adding a generation
/// never rewrites an earlier result, even when the PR head moves.
actor LiveAIHistoryStore: AIHistoryStoreProtocol {

    private let rootDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    func loadGenerations(repositoryIdentity: String, pullRequestNumber: Int) throws -> [AIReviewGeneration] {

        let directory = self.directory(for: repositoryIdentity, number: pullRequestNumber)
            .appendingPathComponent("Generations", isDirectory: true)
        let records: [AIReviewGeneration] = try self.loadRecords(in: directory)

        guard records.allSatisfy({
            $0.repositoryIdentity == repositoryIdentity
                && $0.pullRequestNumber == pullRequestNumber
                && $0.hasConsistentContext
        }) else {
            throw AIReviewError.storageUnavailable
        }

        return records.sorted { $0.createdAt > $1.createdAt }

    }

    func appendGeneration(_ generation: AIReviewGeneration) throws {

        guard generation.hasConsistentContext else {
            throw AIReviewError.invalidResponse("The generation metadata did not match its analyzed PR revision.")
        }

        let directory = self.directory(for: generation.repositoryIdentity, number: generation.pullRequestNumber)
            .appendingPathComponent("Generations", isDirectory: true)
        try self.append(generation, id: generation.id, in: directory)

    }

    func loadConversation(repositoryIdentity: String, pullRequestNumber: Int) throws -> [AIConversationEntry] {

        let directory = self.directory(for: repositoryIdentity, number: pullRequestNumber)
            .appendingPathComponent("Conversation", isDirectory: true)
        let records: [AIConversationEntry] = try self.loadRecords(in: directory)

        guard records.allSatisfy({
            $0.repositoryIdentity == repositoryIdentity
                && $0.pullRequestNumber == pullRequestNumber
                && $0.hasConsistentContext
        }) else {
            throw AIReviewError.storageUnavailable
        }

        return records.sorted { $0.createdAt < $1.createdAt }

    }

    func appendConversation(_ entry: AIConversationEntry) throws {

        guard entry.hasConsistentContext else {
            throw AIReviewError.invalidResponse("The AI activity metadata did not match its analyzed PR revision.")
        }

        let directory = self.directory(for: entry.repositoryIdentity, number: entry.pullRequestNumber)
            .appendingPathComponent("Conversation", isDirectory: true)
        try self.append(entry, id: entry.id, in: directory)

    }

    private func directory(for identity: String, number: Int) -> URL {

        let key = "\(identity.lowercased())#\(number)"
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()

        return self.rootDirectory.appendingPathComponent(name, isDirectory: true)

    }

    private func append<Value: Encodable>(_ value: Value, id: UUID, in directory: URL) throws {

        do {

            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            let fileURL = directory.appendingPathComponent(id.uuidString + ".json")

            guard !FileManager.default.fileExists(atPath: fileURL.path) else {
                throw AIReviewError.storageUnavailable
            }

            let data = try self.encoder.encode(value)
            let stagingURL = directory.appendingPathComponent(".\(UUID().uuidString).tmp")

            defer { try? FileManager.default.removeItem(at: stagingURL) }

            try data.write(to: stagingURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: stagingURL.path)
            try FileManager.default.linkItem(at: stagingURL, to: fileURL)

        } catch {
            throw AIReviewError.storageUnavailable
        }

    }

    private func loadRecords<Value: Decodable>(in directory: URL) throws -> [Value] {

        guard FileManager.default.fileExists(atPath: directory.path) else {
            return []
        }

        do {

            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }

            return try files.map { fileURL in
                let data = try Data(contentsOf: fileURL)
                return try self.decoder.decode(Value.self, from: data)
            }

        } catch {
            throw AIReviewError.storageUnavailable
        }

    }
}
