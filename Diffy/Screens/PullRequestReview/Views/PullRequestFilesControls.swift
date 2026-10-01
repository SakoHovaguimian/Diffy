import SwiftUI

struct PullRequestFilesControls: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var navigator: FileNavigatorViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 16) {

                DiffySegmentedControl(
                    title: "Review Experience",
                    options: ComparisonReviewExperience.allCases,
                    selection: self.$viewModel.experience,
                    label: { $0.rawValue }
                )
                .frame(width: 290, alignment: .leading)
                .help("Browse One File With The Navigator Or Review Collapsible File Cards")
                Spacer()
                Picker("Diff Layout", selection: self.$viewModel.isUnified) {

                    Text("Split").tag(false)
                    Text("Unified").tag(true)

                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)

            }

            if self.viewModel.experience == .review {

                HStack(spacing: 14) {

                    Label("\(self.viewModel.reviewFiles.count.formatted()) Changed Files", systemImage: "doc.on.doc")
                        .fontWeight(.medium)
                    DiffChangeSummary(counts: self.viewModel.counts)
                    Spacer()
                    Text("\(self.viewModel.viewedPaths.count) Of \(self.viewModel.reviewFiles.count) Viewed Locally")
                        .foregroundStyle(self.theme.secondaryText)

                }

                HStack(spacing: 12) {

                    FileNavigatorOptions(
                        viewModel: self.navigator,
                        files: self.viewModel.navigationFiles,
                        mode: .pullRequests,
                        unavailableSortOrders: [.updated, .size],
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
        .padding(16)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

}
