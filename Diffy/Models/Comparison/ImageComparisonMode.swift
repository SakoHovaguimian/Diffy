import Foundation

enum ImageComparisonMode: String, CaseIterable, Identifiable {

    case sideBySide = "Side by side"
    case overlay = "Overlay"
    case slider = "Slider"
    case difference = "Difference"
    case blink = "Blink"

    var id: String { self.rawValue }

}
