import SwiftUI

struct DiffyPullRequestRow: View {

    let content: PullRequestRowContent
    var showsAuthor = true
    var isGrouped = false
    let review: () -> Void
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        HStack(alignment: .top, spacing: self.contentSize.scaled(14)) {

            Image(systemName: "arrow.triangle.pull")
                .font(self.contentSize.font(size: 20, weight: .medium))
                .foregroundStyle(self.content.lifecycle.color(in: self.theme, isDraft: self.content.isDraft))
                .frame(width: self.contentSize.scaled(22))
                .padding(.top, self.contentSize.scaled(3))
                .accessibilityHidden(true)

            ViewThatFits(in: .horizontal) {

                horizontalContent()

                VStack(alignment: .leading, spacing: self.contentSize.scaled(16)) {

                    identity()
                    activity()

                }

            }

        }
        .padding(.horizontal, self.contentSize.scaled(18))
        .padding(.vertical, self.contentSize.scaled(self.isGrouped ? 14 : 18))
        .frame(maxWidth: .infinity, alignment: .leading)

    }

    private func horizontalContent() -> some View {

        HStack(alignment: .top, spacing: self.contentSize.scaled(20)) {

            identity()
                .frame(maxWidth: .infinity, alignment: .leading)

            self.theme.border
                .frame(width: 1, height: self.contentSize.scaled(92))

            activity()
                .frame(width: self.contentSize.scaled(410))

        }
        .frame(minWidth: self.contentSize.scaled(850))

    }

    private func identity() -> some View {
        PullRequestRowIdentity(content: self.content, showsAuthor: self.showsAuthor)
    }

    private func activity() -> some View {
        PullRequestRowActivity(content: self.content, review: self.review)
    }

}
