import Foundation

protocol ReviewExportServiceProtocol {
    func markdown(annotations: [CodeAnnotation], scope: String) -> String
}
