import Foundation

@MainActor
protocol AnnotationServiceProtocol {
    func loadAnnotations() throws -> [CodeAnnotation]
    func saveAnnotations(_ annotations: [CodeAnnotation]) throws
}
