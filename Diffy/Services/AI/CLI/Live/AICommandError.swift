import Foundation

enum AICommandError: LocalizedError {
    case unavailable(String)
    case incompatible(String)
    case failed(name: String, exitStatus: Int32, detail: String?)
    case timedOut
    case oversizedOutput

    var errorDescription: String? {

        switch self {

        case .unavailable(let name):
            "Install \(name), sign in from Terminal, then check availability again."

        case .incompatible(let name):
            "Update \(name) to a version that supports Diffy’s read-only analysis options."

        case .failed(let name, let exitStatus, let detail):
            "\(name) exited with status \(exitStatus). \(detail ?? "No error detail was returned. Check the tool’s sign-in and connection in Terminal.")"

        case .timedOut:
            "The command-line analysis timed out. Try fewer files or another model."

        case .oversizedOutput:
            "The command-line analysis exceeded Diffy’s response limit. Try fewer files."

        }

    }

}
