import Foundation

struct DiffyMarkdownBlock: Identifiable {

    let id: Int
    let text: AttributedString
    let intent: PresentationIntent?

    var headingLevel: Int? {

        self.intent?.components.compactMap { component in
            if case .header(let level) = component.kind { return level }
            return nil
        }.first

    }

    var isCode: Bool {

        self.intent?.components.contains { component in
            if case .codeBlock = component.kind { return true }
            return false
        } ?? false

    }

    var isQuote: Bool {
        self.intent?.components.contains { $0.kind == .blockQuote } ?? false
    }

    var taskCompletion: Bool? {

        guard self.listMarker != nil else { return nil }
        switch String(self.text.characters.prefix(4)).lowercased() {

        case "[x] ": return true
        case "[ ] ": return false
        default: return nil

        }

    }

    var contentText: AttributedString {

        guard self.taskCompletion != nil else { return self.text }
        let start = self.text.characters.index(self.text.startIndex, offsetBy: 4)
        return AttributedString(self.text[start...])

    }

    var listMarker: String? {

        guard let ordinal = self.intent?.components.compactMap({ component -> Int? in
            if case .listItem(let ordinal) = component.kind { return ordinal }
            return nil
        }).first else { return nil }

        let isOrdered = self.intent?.components.contains { $0.kind == .orderedList } ?? false
        return isOrdered ? "\(ordinal)." : "•"

    }

    static func parse(_ markdown: String) -> [DiffyMarkdownBlock] {

        guard let parsed = try? AttributedString(markdown: markdown) else {
            return [DiffyMarkdownBlock(id: 0, text: AttributedString(markdown), intent: nil)]
        }

        return parsed.runs[\.presentationIntent].enumerated().map { index, run in

            let (intent, range) = run
            var text = AttributedString(parsed[range])
            text.presentationIntent = nil
            return DiffyMarkdownBlock(id: index, text: text, intent: intent)

        }

    }

}
