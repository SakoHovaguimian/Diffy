import SwiftUI

struct RepositoryConflictsView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 26) {

                DiffyPageHeading(eyebrow: "Conflict resolution", title: "Bring both sides together.", detail: "Resolve files in your editor, then stage them here. You can also choose one side for an entire file.")

                if let snapshot = self.viewModel.snapshot {

                    operationStatus(snapshot)

                    if snapshot.conflicts.isEmpty {
                        DiffyEmptyState(symbol: "checkmark.circle", title: "No unresolved files", message: snapshot.operation.isInProgress ? "All conflicted paths have been staged. Continue the operation when you're ready." : "Conflicts will appear here when a merge, rebase, or pull needs your input.")
                    } else {

                        LazyVStack(spacing: 12) {
                            ForEach(snapshot.conflicts) { conflict in conflictRow(conflict, snapshot: snapshot) }
                        }

                    }

                }

            }
            .padding(32)

        }

    }

    private func operationStatus(_ snapshot: GitRepositorySnapshot) -> some View {

        HStack(spacing: 18) {

            Image(systemName: snapshot.operation.isInProgress ? "arrow.triangle.merge" : "checkmark.shield")
                .font(.system(size: 23))
                .foregroundStyle(snapshot.operation.isInProgress ? self.theme.modified : self.theme.added)
            VStack(alignment: .leading, spacing: 6) {

                Text(snapshot.operation.title).font(.system(size: 15, weight: .semibold))
                Text("\(snapshot.conflicts.count) unresolved files").font(.system(size: 12)).foregroundStyle(self.theme.secondaryText)

            }
            Spacer()

            if snapshot.operation.supportsContinueAndAbort {

                Button("Abort…", role: .destructive) { self.viewModel.abortOperation() }
                    .disabled(!self.viewModel.canMutate)
                Button("Continue") { self.viewModel.continueOperation() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.viewModel.canMutate || !snapshot.conflicts.isEmpty)

            }

        }
        .padding(22)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(self.theme.border))

    }

    private func conflictRow(_ conflict: GitConflict, snapshot: GitRepositorySnapshot) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                Label(conflict.path, systemImage: "doc.badge.ellipsis")
                    .font(.system(size: 13, weight: .medium))
                    .textSelection(.enabled)
                Spacer()
                DiffyBadge(title: conflict.kind.title, color: self.theme.modified)

            }
            HStack {

                Button("Show file") { ExternalLinkController().reveal(snapshot.location.rootPath + "/" + conflict.path) }
                Menu("Choose whole file") {

                    Button("Use your changes…") { self.viewModel.request(.resolveConflict(path: conflict.path, choice: .yours, stagesResult: true)) }
                    Button("Use incoming changes…") { self.viewModel.request(.resolveConflict(path: conflict.path, choice: .theirs, stagesResult: true)) }

                }
                .disabled(!self.viewModel.canMutate)
                Spacer()
                Button("Stage resolved file") { self.viewModel.request(.stage(paths: [conflict.path])) }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.viewModel.canMutate)

            }
            Text(roleExplanation(snapshot.operation)).font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)

        }
        .padding(20)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 10))

    }

    private func roleExplanation(_ operation: GitOperationState) -> String {

        if case .rebasing = operation {
            return "During a rebase, your changes are the commit being replayed; incoming changes are the branch you're rebasing onto. Deleted files can be resolved by removing the file and staging it."
        }

        return "Your changes are the current branch; incoming changes are the branch being merged. Stage only after you have resolved the file."

    }

}
