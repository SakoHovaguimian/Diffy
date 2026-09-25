import SwiftUI

struct DiffyLoadingState: View {

    let title: String
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        HStack(spacing: self.contentSize.scaled(12)) {

            progressMark()

            VStack(alignment: .leading, spacing: self.contentSize.scaled(2)) {

                Text("IN PROGRESS")
                    .font(self.contentSize.font(size: 8, weight: .semibold))
                    .tracking(self.contentSize.scaled(1.15))
                    .foregroundStyle(self.theme.accent)

                Text(self.title)
                    .font(self.contentSize.font(size: 12, weight: .semibold))
                    .foregroundStyle(self.theme.text)
                    .lineLimit(1)

            }

        }
        .padding(.horizontal, self.contentSize.scaled(14))
        .padding(.vertical, self.contentSize.scaled(10))
        .background(self.backgroundColor, in: RoundedRectangle(cornerRadius: self.contentSize.scaled(12)))
        .overlay {
            RoundedRectangle(cornerRadius: self.contentSize.scaled(12))
                .stroke(self.theme.border.opacity(self.theme.isDark ? 0.82 : 0.72))
        }
        .fixedSize()
        .accessibilityElement(children: .combine)

    }

    private func progressMark() -> some View {

        ZStack {

            RoundedRectangle(cornerRadius: self.contentSize.scaled(8))
                .fill(self.theme.selection)

            RoundedRectangle(cornerRadius: self.contentSize.scaled(8))
                .stroke(self.theme.accent.opacity(0.24))

            ProgressView()
                .controlSize(.small)
                .tint(self.theme.accent)
                .accessibilityHidden(true)

        }
        .frame(
            width: self.contentSize.scaled(34),
            height: self.contentSize.scaled(34)
        )

    }

    private var backgroundColor: Color {
        self.theme.isDark ? self.theme.elevated.opacity(0.94) : self.theme.surface
    }

}

#Preview {

    VStack(alignment: .leading, spacing: 20) {

        DiffyLoadingState(title: "Loading Pull Requests…")
        DiffyLoadingState(title: "Reading Changed Files…")

    }
    .padding(32)
    .withMockPreviews()

}
