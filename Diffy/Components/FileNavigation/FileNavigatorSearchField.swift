import SwiftUI

struct FileNavigatorSearchField: View {

    @Binding var query: String
    var horizontalPadding: CGFloat = 12
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        HStack(spacing: self.contentSize.scaled(7)) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(self.theme.secondaryText)
            TextField("Find A File…", text: self.$query)
                .textFieldStyle(.plain)

            if !self.query.isEmpty {

                Button { self.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear File Search")
                .help("Clear File Search")

            }

        }
        .font(self.contentSize.font(size: 11))
        .padding(self.contentSize.scaled(8))
        .background(self.theme.isDark ? self.theme.elevated : self.theme.surface, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(6)))
        .overlay(RoundedRectangle(cornerRadius: self.contentSize.scaled(6)).stroke(self.theme.isDark ? .clear : self.theme.border))
        .padding(.horizontal, self.contentSize.scaled(self.horizontalPadding))

    }

}
