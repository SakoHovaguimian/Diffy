import SwiftUI

extension PullRequestConversationEntry {

    var symbol: String {

        switch self.state {

        case "APPROVED": "checkmark.seal.fill"
        case "CHANGES_REQUESTED": "exclamationmark.bubble.fill"
        case "DISMISSED": "minus.circle"
        case "PENDING": "clock"
        default: self.kind == .inline ? "chevron.left.forwardslash.chevron.right" : "text.bubble"

        }

    }

    func color(in theme: DiffyTheme) -> Color {

        switch self.state {

        case "APPROVED": theme.added
        case "CHANGES_REQUESTED": theme.modified
        case "DISMISSED", "PENDING": theme.secondaryText
        default: self.kind == .inline ? theme.accent : theme.secondaryText

        }

    }

    var locationTitle: String {

        guard let line = self.line else { return "Outdated comment" }
        return "\(self.side == "LEFT" ? "Old" : "New") line \(line)"

    }

}
