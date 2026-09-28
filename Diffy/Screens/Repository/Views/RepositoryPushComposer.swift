import SwiftUI

struct RepositoryPushComposer: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    private var hasStagedChanges: Bool {
        !(self.viewModel.snapshot?.stagedChanges.isEmpty ?? true)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text(self.viewModel.pushOptions.forceWithLease ? "Force Push With Lease" : "Push Branch")
                .font(.headline)

            if self.hasStagedChanges {

                Text("Write a short message for the staged changes. Diffy will commit them, then push.")
                    .font(.subheadline)
                    .foregroundStyle(self.theme.secondaryText)
                TextField("Commit message", text: self.$viewModel.pushCommitMessage)
                    .textFieldStyle(.roundedBorder)

                if self.viewModel.canSuggestCommitMessage {
                    Button {
                        self.viewModel.suggestCommitMessage(forPush: true)
                    } label: {
                        Label(self.viewModel.isSuggestingCommitMessage ? "Writing…" : "Suggest Short Message", systemImage: "sparkles")
                    }
                    .disabled(self.viewModel.isSuggestingCommitMessage)
                }

                if let error = self.viewModel.commitSuggestionError {
                    Text(error).font(.caption).foregroundStyle(self.theme.removed)
                }

            } else {
                Text("There are no staged changes to commit. Push will send your existing local commits.")
                    .font(.subheadline)
                    .foregroundStyle(self.theme.secondaryText)
            }

            HStack {

                Spacer()
                Button("Cancel") { self.viewModel.showsPushComposer = false }
                    .keyboardShortcut(.cancelAction)
                Button(self.hasStagedChanges ? "Commit & Push" : "Push Existing Commits") {
                    self.viewModel.submitPush()
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.hasStagedChanges && self.viewModel.pushCommitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            }

        }
        .padding(24)
        .frame(width: 440)

    }

}
