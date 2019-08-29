import Foundation
#if !os(Linux)
import CoreLocation
#endif

public protocol JSONType: Codable {
    var jsonValue: Any { get }
}

extension Int: JSONType {
    public var jsonValue: Any { return self }
}
extension String: JSONType {
    public var jsonValue: Any { return self }
}
extension Decimal: JSONType {
    public var jsonValue: Any { return self }
    internal var doubleValue: Double {
        return (self as NSDecimalNumber).doubleValue
    }
}
extension Double: JSONType {
    public var jsonValue: Any { return self }
}
extension Bool: JSONType {
    public var jsonValue: Any { return self }
}

/// Decoded in order of Decimal, Int, Double, Bool, String in order to keep Decimals in tact. Use the helpers (`doubleValue`, `intValue`, `decimalValue`) to get your expected value.
public struct AnyJSONType: JSONType {
    public let jsonValue: Any
    
    /// Converts jsonValue to a Decimal, including if it's an Int or Double
    public var decimalValue: Decimal? {
        return jsonValue as? Decimal
            ?? (jsonValue as? Double).map { Decimal($0) }
            ?? (jsonValue as? Int).map { Decimal($0) }
    }
    
    /// Converts jsonValue to an Int, including if it's a Decimal or Double
    public var intValue: Int? {
        return jsonValue as? Int
            ?? (jsonValue as? Decimal).map { Int($0.doubleValue) }
            ?? (jsonValue as? Double).map(Int.init)
    }
    
    /// Converts jsonValue to a Double, including if it's a Decimal or Double
    public var doubleValue: Double? {
        return jsonValue as? Double
            ?? (jsonValue as? Decimal)?.doubleValue
            ?? (jsonValue as? Int).map(Double.init)
    }
    
    public init(_ value: Any) {
        self.jsonValue = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            jsonValue = NSNull()
        } else if let decimalValue = try? container.decode(Decimal.self) {
            jsonValue = decimalValue
        } else if let intValue = try? container.decode(Int.self) {
            jsonValue = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            jsonValue = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            jsonValue = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            jsonValue = stringValue
        } else if let arrayValue = try? container.decode([AnyJSONType].self) {
            jsonValue = arrayValue
        } else if let dictionaryValue = try? container.decode([String: AnyJSONType].self) {
            jsonValue = dictionaryValue
        } else {
            throw DecodingError.typeMismatch(JSONType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if jsonValue is NSNull {
            try container.encodeNil()
        } else if let decimalValue = jsonValue as? Decimal {
            try container.encode(decimalValue)
        } else if let intValue = jsonValue as? Int {
            try container.encode(intValue)
        } else if let doubleValue = jsonValue as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = jsonValue as? Bool {
            try container.encode(boolValue)
        } else if let stringValue = jsonValue as? String {
            try container.encode(stringValue)
        } else if let arrayValue = jsonValue as? [AnyJSONType] {
            try container.encode(arrayValue)
        } else if let dictionaryValue = jsonValue as? [String: AnyJSONType] {
            try container.encode(dictionaryValue)
        }
    }
}

extension Ring: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = Ring(coordinates: try container.decode([CLLocationCoordinate2D].self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(coordinates)
    }
}
