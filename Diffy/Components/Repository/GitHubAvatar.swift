import SwiftUI

struct GitHubAvatar: View {

    let user: GitHubUserSummary
    let size: CGFloat
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        Group {

            if let avatarURL = self.remoteAvatarURL {

                AsyncImage(url: avatarURL, transaction: Transaction(animation: nil)) { phase in

                    switch phase {

                    case let .success(image):
                        image.resizable().scaledToFill()

                    case .empty, .failure:
                        fallback()

                    @unknown default:
                        fallback()

                    }

                }

            } else {
                fallback()
            }

        }
        .frame(width: self.size, height: self.size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(self.theme.border, lineWidth: 0.75))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("GitHub User @\(self.user.login)")
        .help("@\(self.user.login)")

    }

    private var remoteAvatarURL: URL? {

        guard self.user.avatarURL?.scheme?.lowercased() == "https" else {
            return nil
        }

        return self.user.avatarURL

    }

    private func fallback() -> some View {

        Text(self.user.initials)
            .font(.system(size: max(7, self.size * 0.36), weight: .semibold))
            .foregroundStyle(self.theme.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(self.theme.selection)

    }

}
