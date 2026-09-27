import SwiftUI

struct MergeCompletionView: View {

    @ObservedObject var viewModel: MergeViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        VStack(spacing: self.contentSize.scaled(22)) {

            Image(systemName: "checkmark.circle.fill")
                .font(self.contentSize.font(size: 48, weight: .light))
                .foregroundStyle(self.theme.added)

            VStack(spacing: self.contentSize.scaled(10)) {

                Text("All Conflicts Resolved")
                    .font(self.contentSize.font(size: 26, weight: .semibold))
                    .foregroundStyle(self.theme.text)
                Text("All \(self.viewModel.conflicts.count) conflicts have a resolved result.\nYour draft is ready to review.")
                    .font(self.contentSize.font(size: 13))
                    .foregroundStyle(self.theme.secondaryText)

            }
            .accessibilityElement(children: .combine)

            ViewThatFits(in: .horizontal) {

                HStack(spacing: self.contentSize.scaled(12)) { actions() }
                VStack(spacing: self.contentSize.scaled(12)) { actions() }

            }
            .fixedSize(horizontal: false, vertical: true)

            Text("This temporary draft has not changed your repository.")
                .font(self.contentSize.font(size: 11))
                .foregroundStyle(self.theme.secondaryText)

        }
        .multilineTextAlignment(.center)
        .padding(self.contentSize.scaled(32))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(self.theme.added.opacity(0.035))

    }

    private func actions() -> some View {

        Group {

            Button("Undo Last Resolution") { self.viewModel.undo() }
                .disabled(!self.viewModel.canUndo)
            Button("Review Results") { self.viewModel.reviewResolvedResults() }
                .buttonStyle(.borderedProminent)

        }
        .font(self.contentSize.font(size: 12, weight: .medium))
        .controlSize(.large)

    }

}
