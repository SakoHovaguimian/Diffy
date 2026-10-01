import SwiftUI

struct PullRequestActions: View {

    let webURL: URL
    let review: () -> Void
    @Environment(\.diffyContentSize) private var contentSize

    var body: some View {

        ViewThatFits(in: .horizontal) {

            HStack(spacing: self.contentSize.scaled(8)) {

                githubLink()
                reviewButton()

            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: self.contentSize.scaled(8)) {

                githubLink()
                reviewButton()

            }

        }

    }

    private func githubLink() -> some View {

        Link(destination: self.webURL) {
            Label("Open in GitHub", systemImage: "arrow.up.right")
        }
        .buttonStyle(PullRequestActionButtonStyle(isPrimary: false))

    }

    private func reviewButton() -> some View {

        Button(action: self.review) {
            Label("Review", systemImage: "text.bubble")
        }
        .buttonStyle(PullRequestActionButtonStyle(isPrimary: true))

    }

}
