import SwiftUI

struct WorkspaceHeader: View {

    @ObservedObject var viewModel: WorkspaceViewModel
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabSelection

    private var selectedTabID: String {
        self.viewModel.showsDashboard ? "overview" : self.viewModel.mode.rawValue
    }

    var body: some View {

        let accent = self.viewModel.bucket(for: self.viewModel.project).map { Color(hex: $0.accentHex) } ?? self.theme.accent

        VStack(alignment: .leading, spacing: self.contentSize.scaled(18)) {

            HStack(alignment: .center, spacing: self.contentSize.scaled(12)) {

                Image(systemName: self.viewModel.project.symbol)
                    .font(self.contentSize.font(size: 19))
                    .foregroundStyle(accent)
                    .frame(width: self.contentSize.scaled(39), height: self.contentSize.scaled(39))
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: self.contentSize.scaled(10)))

                VStack(alignment: .leading, spacing: self.contentSize.scaled(3)) {

                    Text(self.viewModel.project.name)
                        .font(self.contentSize.font(size: 20, weight: .semibold))

                    Text(self.viewModel.project.subtitle)
                        .font(self.contentSize.font(size: 11))
                        .foregroundStyle(self.theme.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                }

                Spacer()
                if self.viewModel.project.directoryPath == nil {
                    DiffyBadge(title: "\(self.viewModel.project.changeCount) changes", color: self.theme.modified)
                }

                DiffyIconButton(
                    symbol: self.viewModel.favorites.contains(self.viewModel.project.id) ? "star.fill" : "star",
                    label: "Favorite project"
                ) {
                    self.viewModel.toggleFavorite(self.viewModel.project)
                }

            }

            if self.viewModel.project.directoryPath == nil {

                ScrollView(.horizontal, showsIndicators: false) {

                    HStack(spacing: self.contentSize.scaled(20)) {

                        navigationButton("Working tree", symbol: ComparisonMode.workingTree.symbol, selected: !self.viewModel.showsDashboard && self.viewModel.mode == .workingTree) {
                            self.viewModel.selectMode(.workingTree)
                        }

                        navigationButton("Overview", symbol: "square.grid.2x2", selected: self.viewModel.showsDashboard) {
                            self.viewModel.showsDashboard = true
                        }

                        ForEach(ComparisonMode.allCases.filter { $0 != .workingTree }) { mode in

                            navigationButton(mode.rawValue, symbol: mode.symbol, selected: !self.viewModel.showsDashboard && self.viewModel.mode == mode, available: false) {
                                self.viewModel.selectMode(mode)
                            }

                        }

                    }
                    // Both underline positions must share the same animation transaction.
                    .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.3), value: self.selectedTabID)

                }

            }

        }
        .padding(.horizontal, self.contentSize.scaled(24))
        .padding(.top, self.contentSize.scaled(22))
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: self.contentSize.scaled(1)) }

    }

    private func navigationButton(
        _ title: String,
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
                .overlay(alignment: .bottom) {

                    if selected {

                        self.theme.accent
                            .frame(height: self.contentSize.scaled(2))
                            .matchedGeometryEffect(id: "selected-tab", in: self.tabSelection)

                    }

                }

        }
        .buttonStyle(.plain)
        .help(available ? title : "\(title) placeholder")

    }

}

#Preview {

    WorkspaceHeader(
        viewModel: mockResolve(WorkspaceViewModel.self)
    )
    .frame(width: 1100)
    .withMockPreviews()

}
