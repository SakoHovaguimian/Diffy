import SwiftUI

struct WorkspaceHeader: View {

    @ObservedObject var viewModel: WorkspaceViewModel
    @ObservedObject var repository: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var selectedTabID: String {
        self.viewModel.showsDashboard ? "overview" : self.viewModel.mode.rawValue
    }

    private var changeCount: Int {
        self.repository.snapshot?.changes.count ?? self.viewModel.project.changeCount
    }

    var body: some View {

        let accent = self.viewModel.bucket(for: self.viewModel.project).map { Color(hex: $0.accentHex) } ?? self.viewModel.project.accentHex.map { Color(hex: $0) } ?? self.theme.accent

        VStack(alignment: .leading, spacing: self.contentSize.scaled(18)) {

            HStack(alignment: .center, spacing: self.contentSize.scaled(12)) {

                WorkspaceIdentityIcon(symbol: self.viewModel.project.symbol, customIcon: self.viewModel.project.customIcon, size: self.contentSize.scaled(19))
                    .font(self.contentSize.font(size: 19))
                    .foregroundStyle(accent)
                    .frame(width: self.contentSize.scaled(39), height: self.contentSize.scaled(39))
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(10)))

                VStack(alignment: .leading, spacing: self.contentSize.scaled(3)) {

                    Text(self.viewModel.project.displayName)
                        .font(self.contentSize.font(size: 20, weight: .semibold))

                    Text(self.viewModel.project.displaySubtitle)
                        .font(self.contentSize.font(size: 11))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                }

                Spacer()
                DiffyBadge(
                    title: "\(self.changeCount) Changes",
                    color: self.theme.countColor(for: self.changeCount, activeColor: self.theme.modified)
                )

                DiffyIconButton(symbol: "pencil", label: "Edit Project") {
                    self.viewModel.editProject(self.viewModel.project)
                }

                DiffyIconButton(
                    symbol: self.viewModel.favorites.contains(self.viewModel.project.id) ? "star.fill" : "star",
                    label: "Favorite Project"
                ) {
                    self.viewModel.toggleFavorite(self.viewModel.project)
                }

            }

            Group {

                ScrollView(.horizontal, showsIndicators: false) {

                    HStack(spacing: self.contentSize.scaled(20)) {

                        navigationButton("Overview", id: "overview", symbol: "square.grid.2x2", selected: self.viewModel.showsDashboard) {
                            self.viewModel.showDashboard()
                        }

                        navigationButton("Working Tree", id: ComparisonMode.workingTree.rawValue, symbol: ComparisonMode.workingTree.symbol, selected: !self.viewModel.showsDashboard && self.viewModel.mode == .workingTree) {
                            self.viewModel.selectMode(.workingTree)
                        }

                        ForEach(ComparisonMode.allCases.filter { $0 != .workingTree }) { mode in

                            navigationButton(mode.tabTitle, id: mode.rawValue, symbol: mode.symbol, selected: !self.viewModel.showsDashboard && self.viewModel.mode == mode) {
                                self.viewModel.selectMode(mode)
                            }

                        }

                    }
                    .overlayPreferenceValue(DiffyTabBoundsPreference.self) { bounds in
                        DiffyTabSelectionIndicator(selectedID: self.selectedTabID, bounds: bounds)
                    }

                }

            }

        }
        .padding(.horizontal, self.contentSize.scaled(24))
        .padding(.top, self.contentSize.scaled(22))
        .padding(.bottom, 0)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: self.contentSize.scaled(1)) }

    }

    private func navigationButton(
        _ title: String,
        id: String,
        symbol: String,
        selected: Bool,
        available: Bool = true,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Label(title, systemImage: symbol)
                .font(self.contentSize.font(size: 11, weight: .semibold))
                .foregroundStyle(selected ? self.theme.accent : self.theme.secondaryText.opacity(available ? 1 : 0.65))
                .padding(.bottom, self.contentSize.scaled(13))

        }
        .buttonStyle(.plain)
        .anchorPreference(key: DiffyTabBoundsPreference.self, value: .bounds) { [id: $0] }
        .help(title)

    }

}

#Preview {

    WorkspaceHeader(
        viewModel: mockResolve(WorkspaceViewModel.self),
        repository: mockResolve(WorkspaceViewModel.self).repositoryViewModel
    )
    .frame(width: 1100)
    .withMockPreviews()

}
