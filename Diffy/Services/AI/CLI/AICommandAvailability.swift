import Foundation

struct AICommandAvailability: Sendable {
    let provider: AIProviderKind
    let executablePath: String?
    let problem: String?

    var isAvailable: Bool { self.executablePath != nil && self.problem == nil }
}
