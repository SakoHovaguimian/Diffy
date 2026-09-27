import Foundation

enum WorkspaceIconImageLayout: String, CaseIterable, Identifiable {
    case fit = "Fit"
    case fill = "Fill"

    var id: Self { self }
}
