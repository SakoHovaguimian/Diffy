import SwiftUI

private struct DiffyDataModalSizeKey: EnvironmentKey {
    static let defaultValue = CGSize.zero
}

extension EnvironmentValues {

    var diffyDataModalSize: CGSize {
        get { self[DiffyDataModalSizeKey.self] }
        set { self[DiffyDataModalSizeKey.self] = newValue }
    }

}
