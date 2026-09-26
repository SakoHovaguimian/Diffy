import SwiftUI

struct ComparisonReviewControls: View {

    @ObservedObject var viewModel: ComparisonReviewViewModel
    @ObservedObject var navigator: FileNavigatorViewModel
    @EnvironmentObject private var settings: SettingsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            experienceControls()
            summary()

            if self.viewModel.experience == .review {

                HStack(spacing: 12) {

                    FileNavigatorOptions(
                        viewModel: self.navigator,
                        files: self.viewModel.navigationFiles,
                        mode: self.viewModel.request.mode,
                        horizontalPadding: 0
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    FileNavigatorSearchField(query: self.$navigator.query, horizontalPadding: 0)

                }

            }

            HStack(spacing: 14) {

                Toggle("Unviewed Only", isOn: self.$viewModel.onlyUnviewed)
                    .toggleStyle(.checkbox)
                Spacer()

                if self.viewModel.experience == .review {

                    Button("Expand Shown") { self.viewModel.expandShown() }
                    Button("Collapse All") { self.viewModel.collapseAll() }

                }

            }

        }
        .font(.system(size: 11))
        .controlSize(.small)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }
        .disabled(self.viewModel.isLoading)

    }

    private func experienceControls() -> some View {

        HStack(spacing: 16) {

            Picker("Comparison Experience", selection: self.$viewModel.experience) {
                ForEach(ComparisonReviewExperience.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 290, alignment: .leading)
            .help("Browse One File With The Navigator Or Review Collapsible File Cards")

            Spacer()
            Picker("Diff Layout", selection: self.$settings.editor.unified) {

                Text("Split").tag(false)
                Text("Unified").tag(true)

            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 150)

        }

    }

    private func summary() -> some View {

        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 14) {

                Label("\(self.viewModel.files.count.formatted()) Changed Files", systemImage: "doc.on.doc")
                    .fontWeight(.medium)
                DiffChangeSummary(counts: self.viewModel.counts)
                Spacer()
                Text("\(self.viewModel.viewedCount) Of \(self.viewModel.files.count) Viewed")
                    .foregroundStyle(self.theme.secondaryText)

            }

            if self.viewModel.hasUnavailableLineCounts {
                Text("Line totals exclude files without text counts")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
            }

        }

    }

}
