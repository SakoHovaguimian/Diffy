import SwiftUI

struct PullRequestRowActivity: View {

    let content: PullRequestRowContent
    let review: () -> Void
    @Environment(\.diffyTheme) private var theme
    @Environment(\.diffyContentSize) private var contentSize

    private var checks: PullRequestChecksSummary? {
        self.content.summary?.checks
    }

    private var checksDetail: String {

        guard let checks = self.checks else {
            return "No check runs loaded yet."
        }

        switch checks.state {

        case .success:
            return "\(checks.passed.formatted()) of \(checks.total.formatted()) checks passed."

        case .failure:
            return "\(checks.failed.formatted()) failed · \(checks.pending.formatted()) pending."

        case .pending:
            return "\(checks.pending.formatted()) checks still running."

        case .neutral:
            return "No check runs for this revision."

        case .unavailable:
            return "GitHub checks could not be read."

        }

    }

    var body: some View {

        VStack(alignment: .leading, spacing: self.contentSize.scaled(12)) {

            ViewThatFits(in: .horizontal) {

                HStack(alignment: .center, spacing: self.contentSize.scaled(12)) {

                    checksStatus()
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 0)
                    actions()

                }

                VStack(alignment: .leading, spacing: self.contentSize.scaled(12)) {

                    checksStatus()
                    actions()

                }

            }

            self.theme.border.frame(height: 1)

            PullRequestRowStatistics(summary: self.content.summary)

        }

    }

    private func checksStatus() -> some View {

        HStack(alignment: .top, spacing: self.contentSize.scaled(8)) {

            Image(systemName: self.checks?.state.symbol ?? "circle")
                .font(self.contentSize.font(size: 17))
                .foregroundStyle(self.checks?.state.color(in: self.theme) ?? self.theme.secondaryText)
                .padding(.top, self.contentSize.scaled(1))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: self.contentSize.scaled(4)) {

                Text(self.checks?.state.title ?? "Checks Not Loaded")
                    .font(self.contentSize.font(size: 11, weight: .semibold))
                    .foregroundStyle(self.checks?.state.color(in: self.theme) ?? self.theme.secondaryText)

                Text(self.checksDetail)
                    .font(self.contentSize.font(size: 10))
                    .foregroundStyle(self.theme.secondaryText)

            }

        }
        .help(self.checksDetail)
        .accessibilityElement(children: .combine)

    }

    private func actions() -> some View {
        PullRequestActions(webURL: self.content.webURL, review: self.review)
    }

}
