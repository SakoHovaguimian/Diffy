import SwiftUI

struct PullRequestSubmitReviewView: View {

    @ObservedObject var viewModel: PullRequestReviewViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diffyTheme) private var theme

    var body: some View {

        VStack(alignment: .leading, spacing: 18) {

            Text("Finish Your Review").font(.system(size: 22, weight: .semibold))
            Text("Submitting as \(self.viewModel.account?.handle ?? "") · \(self.viewModel.drafts.count) inline comments")
                .font(.system(size: 12)).foregroundStyle(self.theme.secondaryText)
            Picker("Review Outcome", selection: self.$viewModel.reviewEvent) {

                ForEach(PullRequestReviewEvent.allCases) { event in
                    Text(event.title).tag(event).disabled(event != .comment && !self.viewModel.canDecide)
                }

            }
            .pickerStyle(.radioGroup)
            if !self.viewModel.canDecide {
                Text("You can comment on your own PR or a draft PR. Approval and change requests are unavailable.")
                    .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            }
            TextEditor(text: self.$viewModel.reviewBody)
                .font(.system(size: 13)).frame(height: 160)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(self.theme.border))
                .accessibilityLabel("Review Summary. Required for comments and change requests.")
            Text("Markdown supported. A summary is required for Comment and Request Changes.")
                .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            if let details = self.viewModel.details {
                Text("\(self.viewModel.viewedPaths.count) of \(details.files.count) loaded files viewed · Commit \(details.summary.headSHA.prefix(8))")
                    .font(.system(size: 11)).foregroundStyle(self.theme.secondaryText)
            }
            if let error = self.viewModel.errorMessage {
                DiffyStatusBanner(message: error, isError: true)
            }
            HStack {

                Button("Keep Reviewing") { self.dismiss() }
                Spacer()
                if self.viewModel.isSubmitting { ProgressView().controlSize(.small) }
                Button("Submit Review") { Task { await self.viewModel.submitReview() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.viewModel.canSubmit)

            }

        }
        .padding(28)
        .frame(width: 580)
        .disabled(self.viewModel.isSubmitting)
        .interactiveDismissDisabled(self.viewModel.isSubmitting)

    }

}
