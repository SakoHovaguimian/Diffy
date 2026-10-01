import SwiftUI

struct PullRequestReviewNavigationView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @ObservedObject var aiWorkspace: AIReviewWorkspaceViewModel
    let notesCount: Int
    @Environment(\.diffyTheme) private var theme

    private var availableTabs: [PullRequestReviewTab] {
        PullRequestReviewTab.allCases.filter { tab in
            if tab == .aiNotes {
                return self.notesCount > 0 || !self.aiWorkspace.noteFixes.isEmpty || self.aiWorkspace.proposedFixEntry != nil
            }
            guard let visualization = tab.visualization else { return true }
            return self.aiWorkspace.hasGeneration(for: visualization)
        }
    }

    var body: some View {

        VStack(spacing: 0) {
            tabs()
            controls()
        }

    }

    private func tabs() -> some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 4) {

                ForEach(self.availableTabs) { tab in

                    Button {
                        self.viewModel.selectedTab = tab
                        if let visualization = tab.visualization {
                            self.aiWorkspace.activate(visualization)
                        }
                    } label: {

                        HStack(spacing: 6) {

                            if tab.visualization != nil || tab == .aiNotes {
                                Image(systemName: "sparkles").font(.system(size: 10))
                            }
                            Text(tab.title)
                            if tab == .commits, let count = self.viewModel.details?.commitCount {
                                Text("\(count)").foregroundStyle(self.theme.secondaryText)
                            }
                            if tab == .filesChanged, let count = self.viewModel.details?.changedFileCount {
                                Text("\(count)").foregroundStyle(self.theme.secondaryText)
                            }

                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(self.viewModel.selectedTab == tab ? self.theme.accent : self.theme.secondaryText)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 12)

                    }
                    .buttonStyle(.plain)
                    .anchorPreference(key: DiffyTabBoundsPreference.self, value: .bounds) { [tab.id: $0] }
                    .accessibilityAddTraits(self.viewModel.selectedTab == tab ? .isSelected : [])

                }

            }
            .padding(.horizontal, 12)
            .overlayPreferenceValue(DiffyTabBoundsPreference.self) { bounds in
                DiffyTabSelectionIndicator(selectedID: self.viewModel.selectedTab.id, bounds: bounds)
            }

        }
        .background(alignment: .bottom) { self.theme.border.frame(height: 1) }
        .background(self.theme.surface)

    }

    private func controls() -> some View {

        HStack(spacing: 12) {

            if let summary = self.viewModel.details?.summary {
                Text("Base \(String(summary.baseSHA.prefix(7))) · Head \(String(summary.headSHA.prefix(7)))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
            Button {
                self.viewModel.showsNotes.toggle()
            } label: {
                Label("Review Notes\(self.notesCount == 0 ? "" : " (\(self.notesCount))")", systemImage: "text.bubble")
            }
            .disabled(self.viewModel.noteSource == nil)
            Picker("Review As", selection: self.$viewModel.selectedAccountID) {
                ForEach(self.viewModel.accounts) { Text($0.handle).tag($0.id) }
            }
            .frame(maxWidth: 220)
            .disabled(self.viewModel.isBusy || self.viewModel.hasDrafts)
            .onChange(of: self.viewModel.selectedAccountID) { _, _ in
                Task { await self.viewModel.changeAccount() }
            }
            Button {

                if self.viewModel.hasDrafts { self.viewModel.showsReloadConfirmation = true }
                else { Task { await self.viewModel.load() } }

            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh Pull Request")
            .disabled(self.viewModel.isBusy)
            Button("Review Changes\(self.viewModel.drafts.isEmpty ? "" : " (\(self.viewModel.drafts.count))")") {
                self.viewModel.showsReviewComposer = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(!self.viewModel.canReview)

        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }
}
