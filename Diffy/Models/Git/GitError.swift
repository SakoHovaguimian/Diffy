import Foundation

enum GitError: Error, Hashable, Sendable {
    case executableUnavailable(String)
    case checkoutUnavailable(CheckoutUnavailableReason)
    case notRepository(path: String)
    case commandFailed(GitCommandFailure)
    case cancelled
    case timedOut(subcommand: String)
    case authenticationRequired(remote: String?)
    case nonFastForward
    case missingUpstream(branch: String)
    case detachedHead
    case dirtyWorkingTree(paths: [String])
    case unresolvedConflicts(paths: [String])
    case operationInProgress(GitOperationState)
    case nothingInProgress
    case invalidRevision(String)
    case invalidPath(String)
    case binaryContent(path: String)
    case destinationExists(path: String)
    case writeFailed(path: String, reason: String)
    case unsupported(String)
    case parseFailure(String)
}

extension GitError: LocalizedError {

    var errorDescription: String? {

        switch self {

        case let .executableUnavailable(detail): "Git is unavailable. \(detail)"
        case let .checkoutUnavailable(reason): reason.message
        case .notRepository: "This folder is not a Git repository."
        case let .commandFailed(failure): failure.message.isEmpty ? "git \(failure.subcommand) failed with status \(failure.exitStatus)." : failure.message
        case .cancelled: "The operation was cancelled."
        case let .timedOut(subcommand): "git \(subcommand) took too long and was stopped."
        case let .authenticationRequired(remote): "Git could not authenticate\(remote.map { " with \($0)" } ?? "") without asking for input."
        case .nonFastForward: "The remote has commits that are not in your branch."
        case let .missingUpstream(branch): "\(branch) has no upstream branch."
        case .detachedHead: "HEAD is detached, so there is no branch to update."
        case let .dirtyWorkingTree(paths): "Local changes would be affected (\(paths.count) \(paths.count == 1 ? "file" : "files"))."
        case let .unresolvedConflicts(paths): "\(paths.count) \(paths.count == 1 ? "file still has" : "files still have") conflicts."
        case let .operationInProgress(state): "\(state.title). Finish or abort it first."
        case .nothingInProgress: "There is no merge or rebase to continue."
        case let .invalidRevision(revision): "\(revision) is not a known revision."
        case let .invalidPath(path): "\(path) is outside this repository."
        case let .binaryContent(path): "\(path) is binary and cannot be merged as text."
        case let .destinationExists(path): "\((path as NSString).lastPathComponent) already exists in that folder."
        case let .writeFailed(path, reason): "Could not write \((path as NSString).lastPathComponent): \(reason)"
        case let .unsupported(detail): detail
        case let .parseFailure(detail): "Diffy could not read Git's output. \(detail)"

        }

    }

    var recoverySuggestion: String? {

        switch self {

        case .executableUnavailable: "Choose a Git executable in Settings → Repository."
        case .checkoutUnavailable: "Choose Locate Folder to grant access again."
        case .authenticationRequired: "Confirm that this Mac can reach the remote with its existing SSH agent or credential helper, then try again."
        case .nonFastForward: "Pull first, or push with lease if you intentionally rewrote history."
        case .missingUpstream: "Use Set Upstream and Push to publish this branch."
        case .detachedHead: "Check out a branch before pulling or pushing."
        case .dirtyWorkingTree: "Stage and commit, or discard, your local changes first."
        case .unresolvedConflicts: "Resolve and stage every conflicted file, then continue."
        case .operationInProgress: "Continue or abort the paused operation."
        default: nil

        }

    }
}
