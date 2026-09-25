import Foundation

@MainActor
protocol PreferencesServiceProtocol: AnyObject {

    func load<Value: Decodable>(_ type: Value.Type, key: String) -> Value?
    func save<Value: Encodable>(_ value: Value, key: String)

}
