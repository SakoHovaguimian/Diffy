import SwiftUI

struct AIReviewHistoryView: View {

    @ObservedObject var viewModel: AIReviewWorkspaceViewModel
    let visualization: AIVisualization
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack {

                Text("AI History")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(self.viewModel.historyItems.count.formatted())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)

            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            self.theme.border.frame(height: 1)
            ScrollView {

                LazyVStack(spacing: 4) {

                    ForEach(self.viewModel.historyItems) { generation in
                        historyRow(generation)
                    }
                    if self.viewModel.historyItems.isEmpty {

                        Text("Generated reviews will stay here for this pull request.")
                            .font(.system(size: 11))
                            .foregroundStyle(self.theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)

                    }

                }
                .padding(8)

            }

        }
        .background(self.theme.surface)

    }

    private func historyRow(_ generation: AIReviewGeneration) -> some View {

        let isSelected = self.viewModel.activeGeneration(for: self.visualization)?.id == generation.id

        return Button {
            self.viewModel.selectGeneration(generation)
        } label: {

            VStack(alignment: .leading, spacing: 5) {

                HStack(spacing: 6) {

                    Image(systemName: generation.visualizationType.symbol)
                        .frame(width: 15)
                    Text(generation.visualizationType.title)
                        .fontWeight(.medium)
                    Spacer(minLength: 0)
                    if case .outdated = self.viewModel.revisionStatus(for: generation) {
                        Image(systemName: "clock")
                            .foregroundStyle(self.theme.modified)
                            .help("Analyzed Before The Latest PR Changes")
                    }

                }
                Text(generation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(self.theme.secondaryText)
                Text("\(generation.provider.title) · \(generation.model)")
                    .foregroundStyle(self.theme.secondaryText)
                    .lineLimit(1)
                if !self.viewModel.isSaved(generation) {
                    Text("Not Saved")
                        .foregroundStyle(self.theme.removed)
                }

            }
            .font(.system(size: 11))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? self.theme.selection : Color.clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())

        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(generation.visualizationType.title), \(generation.createdAt.formatted(date: .abbreviated, time: .shortened)), \(generation.provider.title), \(generation.model)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])

    }

}
