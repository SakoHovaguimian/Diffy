import Foundation

enum PullRequestCheckFilter: String, CaseIterable, Identifiable {
    case any
    case passed
    case failed
    case running
    case unavailable

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .any: "Any checks"
        case .passed: "Passed"
        case .failed: "Failed"
        case .running: "Running"
        case .unavailable: "Unavailable"

        }

    }

    func matches(_ request: PullRequestSummary) -> Bool {

        switch self {

        case .any: true
        case .passed: request.checks?.state == .success
        case .failed: request.checks?.state == .failure
        case .running: request.checks?.state == .pending
        case .unavailable: request.checks?.state == .unavailable

        }

    }
}
