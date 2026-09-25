import SwiftUI

struct AINoteFixView: View {

    @ObservedObject var viewModel: AIReviewWorkspaceViewModel
    let canApply: Bool
    let isApplying: Bool
    let applyError: String?
    let applyNotice: String?
    let onApply: (AIConversationEntry) -> Void
    let onOpenFile: (AIConversationEntry, String) -> Void
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        HStack(spacing: 0) {

            proposalContent()
            self.theme.border.frame(width: 1)
            history()
                .frame(width: 240)

        }
        .background(self.theme.background)
        .confirmationDialog("Apply The Proposed Patch?", isPresented: self.$viewModel.showsApplyConfirmation, titleVisibility: .visible) {

            Button("Apply Proposed Patch") {
                if let entry = self.viewModel.pendingApplyEntry {
                    self.onApply(entry)
                }
                self.viewModel.clearPendingApply()
            }
            Button("Keep Reviewing", role: .cancel) { self.viewModel.clearPendingApply() }

        } message: {
            Text("Apply the patch for \(self.viewModel.pendingApplyEntry?.annotationIDs.count ?? 0) review notes at \(self.viewModel.pendingApplyEntry.map { String($0.headSHA.prefix(7)) } ?? "")? Diffy verifies the matching local revision before changing files.")
        }

    }

    @ViewBuilder
    private func proposalContent() -> some View {

        if let entry = self.viewModel.proposedFixEntry, case .noteFix(let proposal) = entry.output {

            VStack(spacing: 0) {

                proposalHeader(entry, proposal: proposal)
                HStack(spacing: 0) {

                    ScrollView {

                        proposalDetails(entry, proposal: proposal)
                            .padding(20)

                    }
                    .frame(width: 330)
                    self.theme.border.frame(width: 1)
                    VStack(alignment: .leading, spacing: 0) {

                        Text("PROPOSED DIFF PREVIEW")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(self.theme.secondaryText)
                            .padding(14)
                        DiffyPatchTextView(text: proposal.proposedPatch, theme: self.theme, fontSize: 11)

                    }
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)

                }

            }

        } else {

            VStack(spacing: 12) {

                if self.viewModel.isAddressingNotes {
                    DiffyLoadingState(title: self.viewModel.requestProgress ?? "Preparing A Proposed Fix…")
                } else {

                    DiffyEmptyState(
                        symbol: "text.badge.checkmark",
                        title: "No Proposed Fix Yet",
                        message: "Select review notes in AI Review and ask AI to address them."
                    )
                    Button("Open AI Review") { self.viewModel.openComposer() }

                }
                if let message = self.viewModel.errorMessage {
                    DiffyStatusBanner(message: message, isError: true)
                        .frame(maxWidth: 480)
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }

    }

    private func proposalHeader(_ entry: AIConversationEntry, proposal: AINoteFixResponse) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 10) {

                Text("Proposed Fix")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
                Button("Apply Proposed Patch") {
                    self.viewModel.prepareApply(entry)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!self.canApply || self.isApplying || proposal.proposedPatch.isEmpty)

            }
            HStack(spacing: 8) {

                DiffyBadge(title: entry.provider.title, color: self.theme.accent, size: .small)
                Text(entry.model)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(self.theme.secondaryText)
                Text("· \(entry.annotationIDs.count) Review \(entry.annotationIDs.count == 1 ? "Note" : "Notes")")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }
            if case .outdated = self.viewModel.revisionStatus(for: entry) {
                DiffyStatusBanner(message: "This proposed fix was analyzed before the latest PR changes. Review its saved diff and generate a new fix for the current revision.")
            }
            if case .unknown = self.viewModel.revisionStatus(for: entry) {
                DiffyStatusBanner(message: "The current PR revision is unavailable. This proposal belongs to the saved revision shown in its history.")
            }
            if !self.canApply {
                Text("Applying requires a matching local checkout and current PR revision.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
            }
            if self.isApplying {
                ProgressView("Applying Proposed Patch…").controlSize(.small)
            }
            if let applyError {
                DiffyStatusBanner(message: applyError, isError: true)
            }
            if let applyNotice {
                DiffyStatusBanner(message: applyNotice)
            }
            if let message = self.viewModel.persistenceMessage {

                DiffyStatusBanner(message: message, isError: true)
                if self.viewModel.unsavedConversationEntry?.id == entry.id {
                    Button("Retry Saving Proposed Fix") { self.viewModel.retrySaveConversation() }
                }

            }

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(self.theme.surface)
        .overlay(alignment: .bottom) { self.theme.border.frame(height: 1) }

    }

    private func proposalDetails(_ entry: AIConversationEntry, proposal: AINoteFixResponse) -> some View {

        VStack(alignment: .leading, spacing: 18) {

            section("Explanation", values: [proposal.explanation])
            section("Fix Plan", values: proposal.plan)
            if !proposal.affectedFiles.isEmpty {

                VStack(alignment: .leading, spacing: 8) {

                    sectionLabel("Affected Files")
                    ForEach(proposal.affectedFiles, id: \.self) { path in
                        Button {
                            self.onOpenFile(entry, path)
                        } label: {
                            Label(path, systemImage: "doc.text.magnifyingglass")
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(self.theme.accent)
                    }

                }

            }
            if !entry.analyzedNotes.isEmpty {

                VStack(alignment: .leading, spacing: 9) {

                    sectionLabel("Review Notes Used")
                    ForEach(Array(entry.analyzedNotes.enumerated()), id: \.offset) { _, note in

                        VStack(alignment: .leading, spacing: 4) {

                            Text("\(note.filePath):\(note.startLine)–\(note.endLine)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(self.theme.secondaryText)
                            Text(note.comment)
                                .font(.system(size: 11))

                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                    }

                }

            }
            if !proposal.uncertainty.isEmpty {
                section("Uncertainty", values: [proposal.uncertainty])
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)

    }

    @ViewBuilder
    private func section(_ title: String, values: [String]) -> some View {

        if !values.isEmpty {

            VStack(alignment: .leading, spacing: 8) {

                sectionLabel(title)
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    Text("\(index + 1). \(value)")
                        .font(.system(size: 12))
                }

            }

        }

    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(self.theme.secondaryText)
    }

    private func history() -> some View {

        VStack(alignment: .leading, spacing: 0) {

            Text("Proposed Fix History")
                .font(.system(size: 13, weight: .semibold))
                .padding(14)
            self.theme.border.frame(height: 1)
            ScrollView {

                LazyVStack(spacing: 4) {

                    ForEach(self.viewModel.noteFixes) { entry in
                        Button {
                            self.viewModel.selectNoteFix(entry)
                        } label: {

                            VStack(alignment: .leading, spacing: 5) {

                                Text(entry.userPrompt)
                                    .font(.system(size: 11, weight: .medium))
                                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                Text("\(entry.provider.title) · \(entry.model)")

                            }
                            .font(.system(size: 10))
                            .foregroundStyle(self.theme.secondaryText)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(self.viewModel.proposedFixEntry?.id == entry.id ? self.theme.selection : Color.clear, in: RoundedRectangle(cornerRadius: 7))

                        }
                        .buttonStyle(.plain)
                    }

                }
                .padding(8)

            }

        }
        .background(self.theme.surface)

    }

}
