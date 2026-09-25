import Foundation

@MainActor
final class AnnotationService: AnnotationServiceProtocol {

    private let fileURL: URL?
    private var memory: [CodeAnnotation] = []
    private var readError: Error?

    init(fileURL: URL?) {
        self.fileURL = fileURL
    }

    // MARK: - Review Storage

    func loadAnnotations() throws -> [CodeAnnotation] {

        guard let fileURL = self.fileURL else {
            return self.memory
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {

            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([CodeAnnotation].self, from: data)

        } catch {

            self.readError = error
            throw error

        }

    }

    func saveAnnotations(_ annotations: [CodeAnnotation]) throws {

        if let readError = self.readError {
            throw readError
        }

        guard let fileURL = self.fileURL else {

            self.memory = annotations
            return

        }

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let data = try JSONEncoder().encode(annotations)
        try data.write(to: fileURL, options: .atomic)

    }

}
