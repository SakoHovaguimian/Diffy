import Foundation

enum FileIconTheme: String, Codable, CaseIterable, Identifiable, Sendable {

    case material
    case vscode
    case catppuccin
    case catppuccinPerfect
    case catppuccinNoctis
    case newage
    case native

    var id: String { self.rawValue }

    var title: String {

        switch self {

        case .material: "Material Icons"
        case .vscode: "VSCode Icons"
        case .catppuccin: "Catppuccin"
        case .catppuccinPerfect: "Catppuccin Perfect"
        case .catppuccinNoctis: "Catppuccin Noctis"
        case .newage: "NewAge Icons"
        case .native: "Native Symbols"

        }

    }

    var detail: String {

        switch self {

        case .material: "Colorful language, tool, and folder icons from Material Icon Theme."
        case .vscode: "Familiar file and folder logos from the VSCode Icons collection."
        case .catppuccin: "Soft pastel icons, with Latte for light workspaces and Mocha for dark."
        case .catppuccinPerfect: "Catppuccin's extended collection of language, tool, and named-folder icons."
        case .catppuccinNoctis: "Minimal file silhouettes and colorful folders from Catppuccin Noctis."
        case .newage: "Compact geometric icons and distinctive folders from NewAge Icons."
        case .native: "Quiet, monochrome SF Symbols that follow your workspace appearance."

        }

    }

    var creditsURL: URL? {

        let address: String

        switch self {

        case .material: address = "https://github.com/material-extensions/vscode-material-icon-theme"
        case .vscode: address = "https://github.com/vscode-icons/vscode-icons#license"
        case .catppuccin: address = "https://github.com/catppuccin/vscode-icons"
        case .catppuccinPerfect: address = "https://github.com/thang-nm/Catppuccin-Perfect-Icons"
        case .catppuccinNoctis: address = "https://github.com/alexdauenhauer/catppuccin-noctis-icons"
        case .newage: address = "https://github.com/bynyck/newage-icons"
        case .native: return nil

        }

        return URL(string: address)

    }

}
