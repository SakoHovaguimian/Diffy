import Foundation

@MainActor
final class PreferencesService: PreferencesServiceProtocol {

    private let defaults: UserDefaults?
    private var memory: [String: Data] = [:]

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    // MARK: - Storage

    func load<Value: Decodable>(_ type: Value.Type, key: String) -> Value? {

        guard let data = self.defaults?.data(forKey: key) ?? self.memory[key] else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)

    }

    func save<Value: Encodable>(_ value: Value, key: String) {

        guard let data = try? JSONEncoder().encode(value) else {
            return
        }

        self.memory[key] = data
        self.defaults?.set(data, forKey: key)

    }

}
