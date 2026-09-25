import SwiftUI

struct MockPreviewModifier: ViewModifier {

    func body(content: Content) -> some View {

        content
            .diffyStyle()
            .environmentObject(mockResolve(SettingsViewModel.self))
            .environmentObject(mockResolve(GitHubAccountsViewModel.self))
            .environmentObject(mockResolve(ReviewViewModel.self))

    }

}

extension View {

    func withMockPreviews() -> some View {
        self.modifier(MockPreviewModifier())
    }

}
