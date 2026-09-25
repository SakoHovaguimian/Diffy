import SwiftUI

struct RepositoryBranchesView: View {

    @ObservedObject var viewModel: RepositoryViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 26) {

                DiffyPageHeading(eyebrow: "Branches & Tags", title: "See Where The Work Goes.", detail: "Compare without checking out. Switch branches when you're ready to move your working tree.")
                if self.viewModel.isLoadingMoreBranches {
                    DiffyLoadingState(title: "Loading More Branches…")
                }
                comparisonPicker()
                HStack {

                    Text("Local Branches").font(.system(size: 16, weight: .semibold))
                    Spacer()
                    TextField("New Branch Name", text: self.$viewModel.newBranchName).textFieldStyle(.roundedBorder).frame(maxWidth: 250)
                    Button("Create Branch") { self.viewModel.request(.createBranch(name: self.viewModel.newBranchName)) }
                        .disabled(!self.viewModel.canMutate || self.viewModel.newBranchName.isEmpty)

                }
                branchList(self.viewModel.snapshot?.localBranches ?? [])

                if !(self.viewModel.snapshot?.remoteBranches.isEmpty ?? true) {

                    Text("Remote Branches").font(.system(size: 16, weight: .semibold))
                    branchList(self.viewModel.snapshot?.remoteBranches ?? [])

                }

                if !(self.viewModel.snapshot?.tags.isEmpty ?? true) {

                    Text("Tags").font(.system(size: 16, weight: .semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], alignment: .leading, spacing: 12) {

                        ForEach(self.viewModel.snapshot?.tags ?? []) { tag in
                            Label(tag.name, systemImage: "tag").font(.system(size: 12)).foregroundStyle(self.theme.secondaryText)
                        }

                    }

                }

            }
            .padding(32)

        }

    }

    private func comparisonPicker() -> some View {

        HStack(spacing: 14) {

            Picker("Base", selection: self.$viewModel.branchBase) {
                ForEach(self.viewModel.snapshot?.branches ?? []) { Text($0.name).tag($0.name) }
            }
            Image(systemName: "arrow.right").foregroundStyle(self.theme.secondaryText)
            Picker("Compare", selection: self.$viewModel.branchTarget) {
                ForEach(self.viewModel.snapshot?.branches ?? []) { Text($0.name).tag($0.name) }
            }
            Button("Compare") { self.viewModel.compareBranches() }
                .buttonStyle(.borderedProminent)
                .disabled(self.viewModel.branchBase.isEmpty || self.viewModel.branchTarget.isEmpty)

        }
        .padding(18)
        .background(self.theme.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(self.theme.border))

    }

    private func branchList(_ branches: [RepositoryBranch]) -> some View {

        LazyVStack(spacing: 0) {

            ForEach(branches) { branch in

                HStack(spacing: 14) {

                    Button { self.viewModel.inspectBranch(branch) } label: {

                        HStack(spacing: 14) {

                            Image(systemName: "arrow.triangle.branch")
                                .foregroundStyle(branch.isCurrent ? self.theme.accent : self.theme.secondaryText)
                            VStack(alignment: .leading, spacing: 6) {

                                Text(branch.name).font(.system(size: 13, weight: .medium)).textSelection(.enabled)
                                Text(branch.upstreamName ?? String(branch.commitID.prefix(7)))
                                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(self.theme.secondaryText)

                            }
                            Spacer()
                            if branch.isCurrent { DiffyBadge(title: "Current", color: self.theme.accent) }

                        }
                        .contentShape(Rectangle())

                    }
                    .buttonStyle(.plain)
                    .disabled(self.viewModel.isLoadingBranchReview)
                    Menu {

                        if !branch.isRemote && !branch.isCurrent {
                            Button("Check Out") { self.viewModel.request(.switchBranch(name: branch.name)) }
                        }
                        Button("Merge Into Current Branch…") { self.viewModel.request(.startMerge(branch: branch.name)) }
                        Button("Rebase Current Branch Onto This…") { self.viewModel.request(.startRebase(onto: branch.name)) }

                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 24)
                    .disabled(!self.viewModel.canMutate || branch.isCurrent)
                    .accessibilityLabel("Actions For \(branch.name)")

                }
                .padding(16)
                .background(branch.isCurrent ? self.theme.selection : self.theme.surface)
                .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

            }

        }
        .clipShape(RoundedRectangle(cornerRadius: 10))

    }

}
