import Foundation

enum AIJSONShapeValidator {

    static func validate(_ data: Data, against schema: AIResponseSchema) throws {

        guard let value = try? JSONSerialization.jsonObject(with: data) else {
            throw AIReviewError.invalidResponse("The provider returned malformed JSON.")
        }

        try self.validate(value, shape: schema.jsonObject)

    }

    private static func validate(_ value: Any, shape: [String: Any]) throws {

        guard let type = shape["type"] as? String else {
            throw AIReviewError.invalidResponse("The response schema is incomplete.")
        }

        switch type {

        case "object": try self.validateObject(value, shape: shape)
        case "array": try self.validateArray(value, shape: shape)
        case "string": try self.validateString(value, shape: shape)
        default: throw AIReviewError.invalidResponse("The response schema has an unsupported field.")

        }

    }

    private static func validateObject(_ value: Any, shape: [String: Any]) throws {

        guard let object = value as? [String: Any],
              let properties = shape["properties"] as? [String: [String: Any]],
              let required = shape["required"] as? [String],
              Set(object.keys) == Set(required),
              Set(required) == Set(properties.keys) else {
            throw AIReviewError.invalidResponse("The response had missing or unexpected fields.")
        }

        for (key, childShape) in properties {

            guard let child = object[key] else {
                throw AIReviewError.invalidResponse("The response had a missing field.")
            }

            try self.validate(child, shape: childShape)

        }

    }

    private static func validateArray(_ value: Any, shape: [String: Any]) throws {

        guard let values = value as? [Any],
              let itemShape = shape["items"] as? [String: Any] else {
            throw AIReviewError.invalidResponse("The response contained an invalid list.")
        }

        for item in values {
            try self.validate(item, shape: itemShape)
        }

    }

    private static func validateString(_ value: Any, shape: [String: Any]) throws {

        guard let string = value as? String else {
            throw AIReviewError.invalidResponse("The response contained an invalid text field.")
        }

        if let choices = shape["enum"] as? [String], !choices.contains(string) {
            throw AIReviewError.invalidResponse("The response contained an unknown classification.")
        }

    }
}
