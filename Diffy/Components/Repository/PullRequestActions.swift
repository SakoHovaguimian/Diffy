import SwiftUI

struct PullRequestActions: View {

    let webURL: URL
    let review: () -> Void

    var body: some View {

        HStack(spacing: 8) {

            Link(destination: self.webURL) {
                Label("Open In GitHub", systemImage: "arrow.up.right")
            }
            .buttonStyle(.bordered)

            Button(action: self.review) {
                Label("Review", systemImage: "text.bubble")
            }
            .buttonStyle(.borderedProminent)

        }
        .controlSize(.small)

    }

}
