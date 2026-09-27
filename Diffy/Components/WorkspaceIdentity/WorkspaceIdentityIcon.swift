import SwiftUI
import AppKit

struct WorkspaceIdentityIcon: View {

    let symbol: String
    let customIcon: WorkspaceCustomIcon?
    var size: CGFloat = 16

    var body: some View {

        Group {

            switch self.customIcon {

            case let .emoji(emoji):
                Text(emoji).font(.system(size: self.size))

            case let .image(data), let .filledImage(data):
                if let image = NSImage(data: data) {
                    customImage(image)
                } else {
                    systemIcon
                }

            case nil:
                systemIcon

            }

        }
        .frame(width: self.size, height: self.size)
        .accessibilityHidden(true)

    }

    private var systemIcon: some View {

        Image(systemName: self.symbol)
            .resizable()
            .scaledToFit()

    }

    @ViewBuilder
    private func customImage(_ image: NSImage) -> some View {

        let shape = RoundedRectangle(cornerRadius: self.size * 0.22)

        if self.customIcon?.imageLayout == .fill {

            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: self.size, height: self.size)
                .clipShape(shape)

        } else {

            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(shape)

        }

    }

}
