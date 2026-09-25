import SwiftUI

@main
@MainActor
struct DiffyApp: App {

    private let appAssembler = AppAssembler()

    var body: some Scene {

        WindowGroup {

            WorkspaceScreen(viewModel: self.appAssembler.viewModels.workspaceViewModel())
                .diffyStyle()
                .environmentObject(self.appAssembler.viewModels.settingsViewModel)
                .environmentObject(self.appAssembler.viewModels.gitHubAccountsViewModel)
                .environmentObject(self.appAssembler.viewModels.reviewViewModel)

        }
        .defaultSize(width: 1480, height: 920)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            DiffyCommands()
        }

        Settings {

            SettingsScreen()
                .diffyStyle()
                .environmentObject(self.appAssembler.viewModels.settingsViewModel)
                .environmentObject(self.appAssembler.viewModels.gitHubAccountsViewModel)

        }

    }

}
