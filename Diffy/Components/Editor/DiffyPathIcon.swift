import SwiftUI

struct DiffyPathIcon: View {

    let path: String
    var isFolder = false
    var isExpanded = false
    var isBinary = false
    var size: CGFloat = 16
    @Environment(\.fileIconTheme) private var iconTheme
    @Environment(\.fileIconService) private var iconService
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        icon
            .frame(width: self.contentSize.scaled(self.size), height: self.contentSize.scaled(self.size))
            .frame(width: self.contentSize.scaled(self.size + 4))
            .accessibilityHidden(true)

    }

    @ViewBuilder
    private var icon: some View {

        if let image = self.iconService?.image(
            for: self.path,
            isFolder: self.isFolder,
            isExpanded: self.isExpanded,
            theme: self.iconTheme,
            isDark: self.theme.isDark
        ) {

            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()

        } else {

            Image(systemName: NativeFileIcon.symbol(for: self.path, isFolder: self.isFolder, isBinary: self.isBinary))
                .font(self.contentSize.font(size: self.size, weight: .regular))
                .foregroundStyle(self.theme.secondaryText)

        }

    }

}
