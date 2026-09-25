import SwiftUI

struct RepositoryPatchView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme
    @EnvironmentObject private var settings: SettingsViewModel

    var body: some View {

        VStack(spacing: 0) {

            HStack {

                Label(self.viewModel.patchTitle.isEmpty ? "Comparison" : self.viewModel.patchTitle, systemImage: "rectangle.split.2x1")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("READ ONLY").font(.system(size: 9, weight: .semibold)).tracking(1).foregroundStyle(self.theme.secondaryText)

            }
            .padding(16)
            .background(self.theme.elevated)
            Divider()

            if self.viewModel.isLoadingPatch {
                DiffyLoadingState(title: "Reading Comparison…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = self.viewModel.patchError {
                DiffyEmptyState(symbol: "exclamationmark.circle", title: "Comparison Unavailable", message: error)
            } else if self.viewModel.patchText.isEmpty {
                DiffyEmptyState(symbol: "checkmark.circle", title: self.viewModel.patchTitle.isEmpty ? "Choose A Change" : "No Differences", message: "Select a file, commit, or branch comparison to inspect its patch.")
            } else {

                DiffyPatchTextView(text: self.viewModel.patchText, theme: self.theme, fontSize: self.settings.editor.fontSize)

                if self.viewModel.patchText.count > 1_000_000 {
                    DiffyStatusBanner(message: "Preview shows the first 1 million characters. Select a single file for a smaller comparison.")
                }

            }

        }
        .background(self.theme.surface)

    }

}
