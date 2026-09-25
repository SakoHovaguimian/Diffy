import SwiftUI

struct AISettingsScreen: View {

    @ObservedObject var viewModel: AISettingsViewModel
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Form {

            if let error = self.viewModel.errorMessage {
                DiffyStatusBanner(message: error, isError: true)
            }

            if let notice = self.viewModel.notice {
                DiffyStatusBanner(message: notice)
            }

            defaultsSection()
                .disabled(self.viewModel.isBusy)
            providerSection()
                .disabled(self.viewModel.isBusy)
            installedToolsSection()

            Section("Local History") {

                Text(self.viewModel.usesPersistentStorage
                     ? "Every analysis stays on this Mac with the exact PR revisions it analyzed. New generations keep the earlier results. API keys are stored separately in macOS Keychain."
                     : "Mock and previews keep AI activity in memory for this session. They do not read saved history, run installed tools, or access Keychain.")
                Text("In Diffy Live, Generate sends the selected PR context to your chosen provider. Installed tools use their own sign-in; their availability does not confirm authentication or model access.")
                Text("Diffy never applies an AI proposal automatically. Review the patch and choose Apply when you are ready.")

            }
            .font(.caption)
            .foregroundStyle(self.theme.secondaryText)

        }
        .formStyle(.grouped)
        .task { await self.viewModel.load() }
        .onDisappear { self.viewModel.apiKeyDraft = "" }

    }

    private func defaultsSection() -> some View {

        Section("Review Defaults") {

            Picker("Connection", selection: self.$viewModel.settings.defaultRoute) {
                ForEach(AIExecutionRoute.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .onChange(of: self.viewModel.settings.defaultRoute) { _, _ in
                self.viewModel.selectDefaultProvider()
            }

            Picker("Default Provider", selection: self.$viewModel.settings.defaultProvider) {
                ForEach(AIProviderKind.allCases) { Text($0.title).tag($0) }
            }
            .onChange(of: self.viewModel.settings.defaultProvider) { _, _ in
                self.viewModel.selectDefaultProvider()
            }

            HStack {

                TextField("Default Model ID", text: self.$viewModel.settings.defaultModel)
                Menu("Available Models") {

                    ForEach(self.viewModel.settings.models(
                        for: self.viewModel.settings.defaultProvider,
                        route: self.viewModel.settings.defaultRoute
                    ), id: \.self) { model in
                        Button(model) { self.viewModel.settings.defaultModel = model }
                    }

                }

            }

            Text("You can override the provider, connection, and model before each request. Model IDs must be supported by the selected provider or installed tool.")
                .font(.caption)
                .foregroundStyle(self.theme.secondaryText)

            Button("Save AI Settings") { Task { await self.viewModel.saveSettings() } }
                .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels)

        }

    }

    private func providerSection() -> some View {

        Section("Provider Setup") {

            Picker("Provider", selection: self.$viewModel.selectedProvider) {
                ForEach(AIProviderKind.allCases) { Text($0.title).tag($0) }
            }
            .disabled(self.viewModel.isBusy)

            Picker("Connection For Model List", selection: self.$viewModel.selectedRoute) {
                ForEach(AIExecutionRoute.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .disabled(self.viewModel.isBusy)

            HStack {

                if self.viewModel.showsAPIKey {
                    TextField("New API Key", text: self.$viewModel.apiKeyDraft)
                } else {
                    SecureField("New API Key", text: self.$viewModel.apiKeyDraft)
                }

                Button {
                    self.viewModel.showsAPIKey.toggle()
                } label: {
                    Image(systemName: self.viewModel.showsAPIKey ? "eye.slash" : "eye")
                }
                .accessibilityLabel(self.viewModel.showsAPIKey ? "Hide API Key" : "Show API Key")

            }

            HStack {

                Button(self.viewModel.usesPersistentStorage ? "Save Key In Keychain" : "Save Demo Key") {
                    Task { await self.viewModel.saveAPIKey() }
                }
                    .disabled(self.viewModel.isBusy || self.viewModel.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if self.viewModel.savedKeyProviders.contains(self.viewModel.selectedProvider) {

                    Label(self.viewModel.usesPersistentStorage ? "Key Saved" : "Demo Ready", systemImage: "key.fill")
                        .font(.caption)
                    Spacer()
                    Button("Remove Key", role: .destructive) { Task { await self.viewModel.removeAPIKey() } }
                        .disabled(self.viewModel.isBusy)

                }

            }

            HStack(spacing: 10) {

                Text("\(self.viewModel.selectedProvider.title) · \(self.viewModel.selectedRoute.title) Models")
                    .font(.caption)
                Spacer()
                if self.viewModel.isDiscoveringModels {
                    ProgressView().controlSize(.small)
                }
                Button("Refresh Models") { self.viewModel.refreshModels() }
                    .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels)

            }
            if let source = self.viewModel.modelSource {
                Text("Source: \(source)")
                    .font(.caption)
                    .foregroundStyle(self.theme.secondaryText)
            }
            if let notice = self.viewModel.modelNotice {
                DiffyStatusBanner(message: notice)
            }
            if let error = self.viewModel.modelError {
                DiffyStatusBanner(message: error, isError: true)
            }
            TextEditor(text: self.$viewModel.modelsText)
                .font(.system(size: 12, design: .monospaced))
                .frame(minHeight: 70, maxHeight: 110)
                .accessibilityLabel("Available Model IDs")
                .disabled(self.viewModel.isBusy || self.viewModel.isDiscoveringModels)
            Text("One model ID per line. Refresh fetches models for this connection; you can still enter a model ID manually. Save AI Settings to keep the list.")
                .font(.caption)
                .foregroundStyle(self.theme.secondaryText)

        }

    }

    private func installedToolsSection() -> some View {

        Section("Installed Command-Line Tools") {

            ForEach(AIProviderKind.allCases) { provider in

                HStack(alignment: .top) {

                    VStack(alignment: .leading, spacing: 4) {

                        Text(provider.commandTitle)

                        if let status = self.viewModel.installedCommands[provider] {

                            Text(status.executablePath ?? status.problem ?? "Not Installed")
                                .font(.caption)
                                .foregroundStyle(self.theme.secondaryText)
                                .textSelection(.enabled)

                        }

                    }
                    Spacer()

                    if let url = provider.commandSetupURL {
                        Link("Setup", destination: url)
                    }

                }

            }

            Button("Check Installed Tools") { Task { await self.viewModel.refreshAvailability() } }
                .disabled(self.viewModel.isBusy)

        }

    }

}
