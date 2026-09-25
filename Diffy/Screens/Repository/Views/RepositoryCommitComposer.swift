import SwiftUI

struct RepositoryCommitComposer: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {

                Text("Next Commit").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(self.viewModel.snapshot?.stagedChanges.count ?? 0) Staged").font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)

            }
            TextField("Summarize Your Changes", text: self.$viewModel.commitMessage, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .disabled(self.viewModel.isOperating)
            Button {
                self.viewModel.request(.commit(message: self.viewModel.commitMessage))
            } label: {
                Label("Commit Staged Changes", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!self.viewModel.canMutate || self.viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (self.viewModel.snapshot?.stagedChanges.isEmpty ?? true) || (self.viewModel.snapshot?.operation.isInProgress ?? false))
            Text("Uses the author configured in this repository.").font(.system(size: 10)).foregroundStyle(self.theme.secondaryText)

        }
        .padding(16)
        .background(self.theme.surface)

    }

}
