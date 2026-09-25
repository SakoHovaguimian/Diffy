import SwiftUI

struct AIReviewComposerView: View {

    @ObservedObject var viewModel: AIReviewWorkspaceViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(spacing: 0) {

            VStack(alignment: .leading, spacing: 12) {

                heading()
                loadingStatus()

            }
            .padding(20)
            self.theme.border.frame(height: 1)
            ScrollView {

                VStack(alignment: .leading, spacing: 18) {

                    settings()
                    contextSelection()
                    visualizationActions()
                    questionSection()
                    notesSection()
                    questionHistory()
                    messages()

                }
                .padding(20)

            }

        }
        .frame(width: 470, height: 640)
        .background(self.theme.surface)

    }

    @ViewBuilder
    private func loadingStatus() -> some View {

        if !self.viewModel.loadingMessages.isEmpty {

            VStack(alignment: .leading, spacing: 8) {

                ForEach(self.viewModel.loadingMessages, id: \.self) { message in
                    DiffyLoadingState(title: message)
                }
                if self.viewModel.isBusy {

                    Button("Cancel AI Request") {

                        if self.viewModel.isGenerating { self.viewModel.cancelGeneration() }
                        if self.viewModel.isAsking { self.viewModel.cancelQuestion() }
                        if self.viewModel.isAddressingNotes { self.viewModel.cancelNoteFix() }

                    }
                    .font(.system(size: 11))

                }

            }

        }

    }

    private func heading() -> some View {

        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 4) {

                Label("AI Review", systemImage: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Text("Use this pull request’s changes as context.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)

            }
            Spacer()
            Button {
                self.viewModel.showsComposer = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close AI Review Composer")

        }

    }

    private func settings() -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 10) {

                Picker("Provider", selection: Binding(
                    get: { self.viewModel.selectedProvider },
                    set: { self.viewModel.selectProvider($0) }
                )) {
                    ForEach(AIProviderKind.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .disabled(self.viewModel.isBusy)
                Picker("Source", selection: Binding(
                    get: { self.viewModel.selectedRoute },
                    set: { self.viewModel.selectRoute($0) }
                )) {
                    ForEach(AIExecutionRoute.allCases) { route in
                        Text(route.title).tag(route)
                    }
                }
                .disabled(self.viewModel.isBusy)

            }
            HStack(spacing: 8) {

                TextField("Model ID", text: self.$viewModel.selectedModel)
                    .textFieldStyle(.roundedBorder)
                    .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels)
                Menu("Available Models") {

                    ForEach(self.viewModel.modelChoices, id: \.self) { model in
                        Button(model) { self.viewModel.selectedModel = model }
                    }

                }
                .disabled(self.viewModel.modelChoices.isEmpty || self.viewModel.isDiscoveringModels)

            }
            HStack(spacing: 12) {

                Button("Use Default AI Settings") { self.viewModel.useDefaultModel() }
                Button("Refresh Models") { self.viewModel.refreshModels() }
                    .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels)
            }
            .font(.system(size: 11))
            if let source = self.viewModel.modelSource {
                Text("Models From: \(source)")
                    .font(.system(size: 10))
                    .foregroundStyle(self.theme.secondaryText)
            }
            if let notice = self.viewModel.modelNotice {
                DiffyStatusBanner(message: notice)
            }
            if let error = self.viewModel.modelError {
                DiffyStatusBanner(message: error, isError: true)
            }
            if self.viewModel.selectedRoute == .installedCLI {

                if let status = self.viewModel.commandStatus {

                    Label(
                        status.isAvailable ? "Installed Tool Found: \(status.executablePath ?? "")" : status.problem ?? "Command Line Tool Is Unavailable",
                        systemImage: status.isAvailable ? "checkmark.circle" : "exclamationmark.circle"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(status.isAvailable ? self.theme.added : self.theme.removed)
                    .textSelection(.enabled)

                } else {
                    Text("Checking the installed command line tool…")
                        .font(.system(size: 11))
                        .foregroundStyle(self.theme.secondaryText)
                }

            } else {
                Text("API keys are stored in macOS Keychain. Configure them in Settings → AI Review.")
                    .font(.system(size: 11))
                    .foregroundStyle(self.theme.secondaryText)
            }
            Text("You can enter a model ID manually if it is supported by this provider and connection.")
                .font(.system(size: 10))
                .foregroundStyle(self.theme.secondaryText)

        }

    }

    private func contextSelection() -> some View {

        VStack(alignment: .leading, spacing: 8) {

            DisclosureGroup(isExpanded: self.$viewModel.showsFileSelection) {

                HStack(spacing: 6) {

                    TextField("Filter Changed Files", text: self.$viewModel.fileQuery)
                        .textFieldStyle(.roundedBorder)
                    if !self.viewModel.fileQuery.isEmpty {
                        Button {
                            self.viewModel.fileQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear File Search")
                    }

                }
                .padding(.top, 7)
                ForEach(self.visibleFiles, id: \.filename) { file in
                    Toggle(isOn: Binding(
                        get: { self.viewModel.selectedPaths.contains(file.filename) },
                        set: { selected in

                            if selected { self.viewModel.selectedPaths.insert(file.filename) }
                            else { self.viewModel.selectedPaths.remove(file.filename) }

                        }
                    )) {
                        Text(file.filename)
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1)
                    }
                    .toggleStyle(.checkbox)
                }
                if self.visibleFiles.count == 50 {
                    Text("Showing The First 50 Matches. Narrow The Filter To Find More Files.")
                        .font(.system(size: 10))
                        .foregroundStyle(self.theme.secondaryText)
                }

            } label: {
                Text("Selected Files (\(self.viewModel.selectedPaths.count))")
                    .font(.system(size: 11, weight: .medium))
            }
            Text("No selection analyzes a bounded set of PR changes. Selecting files limits the analysis to those files.")
                .font(.system(size: 10))
                .foregroundStyle(self.theme.secondaryText)

        }

    }

    private var visibleFiles: [PullRequestReviewFile] {

        let query = self.viewModel.fileQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = self.viewModel.availableFiles.filter { file in
            query.isEmpty || file.filename.localizedCaseInsensitiveContains(query)
        }
        return Array(matching.prefix(50))

    }

    private func visualizationActions() -> some View {

        VStack(alignment: .leading, spacing: 9) {

            sectionLabel("Understand This Pull Request")
            TextField("Add A Focus Or Question (Optional)", text: self.$viewModel.userPrompt, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            ForEach(AIVisualization.allCases) { visualization in

                Button {

                    self.viewModel.selectedVisualization = visualization
                    self.viewModel.generate()

                } label: {

                    HStack(spacing: 10) {

                        Image(systemName: visualization.symbol)
                            .frame(width: 18)
                            .foregroundStyle(self.theme.accent)
                        VStack(alignment: .leading, spacing: 3) {

                            Text(visualization.title)
                                .font(.system(size: 12, weight: .semibold))
                            Text(visualization.purpose)
                                .font(.system(size: 10))
                                .foregroundStyle(self.theme.secondaryText)

                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(self.theme.secondaryText)

                    }
                    .padding(10)
                    .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(self.theme.border, lineWidth: 1))

                }
                .buttonStyle(.plain)
                .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels || !self.viewModel.hasCurrentDetails)
                .accessibilityLabel("Generate \(visualization.title)")

            }

        }

    }

    private func questionSection() -> some View {

        VStack(alignment: .leading, spacing: 9) {

            sectionLabel("Ask About This Change")
            TextField("What Do You Want To Understand?", text: self.$viewModel.questionText, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            HStack {

                Button("Ask AI") { self.viewModel.askQuestion() }
                    .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels || !self.viewModel.hasCurrentDetails || self.viewModel.questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Spacer()
            }

        }

    }

    @ViewBuilder
    private func notesSection() -> some View {

        if !self.viewModel.annotations.isEmpty {

            VStack(alignment: .leading, spacing: 9) {

                DisclosureGroup(isExpanded: self.$viewModel.showsNotes) {

                    ForEach(self.viewModel.annotations) { note in
                        Toggle(isOn: Binding(
                            get: { self.viewModel.selectedAnnotationIDs.contains(note.id) },
                            set: { self.viewModel.setAnnotationSelected(note.id, selected: $0) }
                        )) {

                            VStack(alignment: .leading, spacing: 3) {

                                Text("\(note.filePath):\(note.startLine)–\(note.endLine)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .lineLimit(1)
                                Text(note.comment)
                                    .font(.system(size: 11))
                                    .lineLimit(2)

                            }

                        }
                        .toggleStyle(.checkbox)
                    }

                } label: {
                    Text("Review Notes (\(self.viewModel.selectedAnnotationIDs.count) Selected)")
                        .font(.system(size: 11, weight: .medium))
                }
                Button("Ask AI To Address Notes") { self.viewModel.addressSelectedNotes() }
                    .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels || !self.viewModel.hasCurrentDetails || self.viewModel.selectedAnnotationIDs.isEmpty)

            }

        }

    }

    @ViewBuilder
    private func questionHistory() -> some View {

        let entries = self.viewModel.recentQuestions
        if !entries.isEmpty {

            VStack(alignment: .leading, spacing: 9) {

                sectionLabel("Question History")
                ForEach(entries) { entry in

                    if case .question(let answer) = entry.output {

                        VStack(alignment: .leading, spacing: 6) {

                            Text(entry.userPrompt)
                                .font(.system(size: 11, weight: .semibold))
                            Text(answer.answer)
                                .font(.system(size: 11))
                                .foregroundStyle(self.theme.secondaryText)
                                .textSelection(.enabled)
                            if !answer.evidence.isEmpty {
                                Text("Evidence: \(answer.evidence.joined(separator: " · "))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(self.theme.secondaryText)
                                    .textSelection(.enabled)
                            }
                            if !answer.relevantFiles.isEmpty {
                                Text("Files: \(answer.relevantFiles.joined(separator: " · "))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(self.theme.secondaryText)
                                    .textSelection(.enabled)
                            }
                            if !answer.uncertainty.isEmpty {
                                Text("Uncertainty: \(answer.uncertainty)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(self.theme.secondaryText)
                                    .textSelection(.enabled)
                            }
                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 10))
                                .foregroundStyle(self.theme.secondaryText)
                            Text("\(entry.provider.title) · \(entry.model) · \(String(entry.baseSHA.prefix(7))) → \(String(entry.headSHA.prefix(7)))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(self.theme.secondaryText)
                            if case .outdated = self.viewModel.revisionStatus(for: entry) {
                                Label("Answered Before The Latest PR Changes", systemImage: "clock.arrow.circlepath")
                                    .font(.system(size: 10))
                                    .foregroundStyle(self.theme.modified)
                            }
                            if case .unknown = self.viewModel.revisionStatus(for: entry) {
                                Label("Current PR Revision Unavailable", systemImage: "info.circle")
                                    .font(.system(size: 10))
                                    .foregroundStyle(self.theme.secondaryText)
                            }

                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(self.theme.elevated, in: RoundedRectangle(cornerRadius: 7))

                    }

                }

            }

        }

    }

    @ViewBuilder
    private func messages() -> some View {

        if let message = self.viewModel.errorMessage {
            DiffyStatusBanner(message: message, isError: true)
        }
        if let message = self.viewModel.persistenceMessage {

            DiffyStatusBanner(message: message, isError: true)
            if self.viewModel.unsavedGeneration != nil {
                Button("Retry Saving Review") { self.viewModel.retrySaveGeneration() }
            }
            if self.viewModel.unsavedConversationEntry != nil {
                Button("Retry Saving AI Activity") { self.viewModel.retrySaveConversation() }
            }

        }

    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(self.theme.secondaryText)
    }

}
