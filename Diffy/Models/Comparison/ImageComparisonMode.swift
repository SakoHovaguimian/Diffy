import Foundation

enum ImageComparisonMode: String, CaseIterable, Identifiable {

    case sideBySide = "Side By Side"
    case overlay = "Overlay"
    case slider = "Slider"
    case difference = "Difference"
    case blink = "Blink"

    var id: String { self.rawValue }

}
