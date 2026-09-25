import SwiftUI

struct RepositoryBranchPicker: View {

    let branches: [RepositoryBranch]
    @Binding var selection: String

    var body: some View {

        Picker("Browse Branch", selection: self.$selection) {

            if self.showsSelectedReference {
                Text(self.selection).tag(self.selection)
            }

            if !self.localBranches.isEmpty {

                Section("Local") {

                    ForEach(self.localBranches) { branch in
                        Text(branch.isCurrent ? "\(branch.name) · Current" : branch.name)
                            .tag(branch.name)
                    }

                }

            }

            if !self.remoteBranches.isEmpty {

                Section("Remote") {

                    ForEach(self.remoteBranches) { branch in
                        Text(branch.name).tag(branch.name)
                    }

                }

            }

        }
        .pickerStyle(.menu)
        .disabled(self.branches.isEmpty)
        .help("Browse This Branch Without Checking It Out")

    }

    private var localBranches: [RepositoryBranch] {
        self.branches.filter { !$0.isRemote }
    }

    private var remoteBranches: [RepositoryBranch] {
        self.branches.filter(\.isRemote)
    }

    private var showsSelectedReference: Bool {
        !self.selection.isEmpty && !self.branches.contains { $0.name == self.selection }
    }

}
