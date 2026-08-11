import Foundation
import Darwin

struct AIRegionProfile: Equatable {
    let marketingName: String
    let regulatoryModel: String

    private static let regulatoryModels: [String: String] = [
        "iPhone 17e": "A3575",
        "iPhone 17 Pro Max": "A3257",
        "iPhone 17 Pro": "A3256",
        "iPhone 17": "A3258",
        "iPhone Air": "A3260",
        "iPhone 16e": "A3212",
        "iPhone 16 Pro Max": "A3084",
        "iPhone 16 Pro": "A3083",
        "iPhone 16 Plus": "A3082",
        "iPhone 16": "A3081",
        "iPhone 15 Pro Max": "A2849",
        "iPhone 15 Pro": "A2848"
    ]

    private static let productTypes: [String: String] = [
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e"
    ]

    init?(plist: GestaltPlist) {
        let cacheExtra = plist.cacheExtra
        let marketingKeys = [
            "Z/dqyWS6OZTRy10UcmUAhw",
            "bbtR9jQx50Fv5Af/affNtA"
        ]

        let storedName = marketingKeys
            .compactMap { cacheExtra[$0] as? String }
            .first { Self.regulatoryModels[$0] != nil }
        let storedProductType = cacheExtra["0+nc/Udy4WNG8S+Q7a/s1A"] as? String
        let productType = storedProductType ?? Self.machineIdentifier
        let marketingName = storedName ?? Self.productTypes[productType]

        guard let marketingName,
              let regulatoryModel = Self.regulatoryModels[marketingName] else {
            return nil
        }
        self.marketingName = marketingName
        self.regulatoryModel = regulatoryModel
    }

    private static var machineIdentifier: String {
        var size = 0
        guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0,
              size > 0 else { return "" }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.machine", &value, &size, nil, 0) == 0 else {
            return ""
        }
        return String(cString: value)
    }
}

struct GestaltNotice: Identifiable {
    enum Kind { case error, restartRequired, backupCreated }

    let id = UUID()
    let kind: Kind
    let message: String

    var title: String {
        switch kind {
        case .error: "操作失败"
        case .restartRequired: "写入完成"
        case .backupCreated: "备份完成"
        }
    }
}

enum PlistValueKind: String, CaseIterable, Identifiable {
    case string
    case integer
    case float
    case boolean
    case data
    case array
    case dictionary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .string: "String"
        case .integer: "Integer"
        case .float: "Float"
        case .boolean: "Boolean"
        case .data: "Data"
        case .array: "Array"
        case .dictionary: "Dictionary"
        }
    }

    static func kind(of value: Any?) -> PlistValueKind {
        switch value {
        case is String:
            .string
        case let number as NSNumber:
            CFGetTypeID(number) == CFBooleanGetTypeID()
                ? .boolean
                : (CFNumberIsFloatType(number) ? .float : .integer)
        case is Data:
            .data
        case is NSArray:
            .array
        case is NSDictionary:
            .dictionary
        default:
            .string
        }
    }
}

struct PlistValueInfo {
    let kind: PlistValueKind
    let summary: String
    let searchText: String

    static func info(for value: Any?) -> PlistValueInfo {
        let kind = PlistValueKind.kind(of: value)
        let text = encode(value, as: kind)
        let summary: String

        switch kind {
        case .string:
            summary = text.isEmpty ? "Empty string" : text
        case .integer, .float, .boolean:
            summary = text
        case .data:
            summary = "Data (\((value as? Data)?.count ?? 0) bytes)"
        case .array:
            summary = "Array (\((value as? NSArray)?.count ?? 0) items)"
        case .dictionary:
            summary = "Dictionary (\((value as? NSDictionary)?.count ?? 0) items)"
        }

        return PlistValueInfo(kind: kind, summary: summary, searchText: text)
    }

    static func encode(_ value: Any?, as kind: PlistValueKind) -> String {
        switch kind {
        case .string:
            value as? String ?? ""
        case .integer, .float:
            (value as? NSNumber)?.stringValue ?? ""
        case .boolean:
            (value as? NSNumber)?.boolValue == true ? "true" : "false"
        case .data:
            (value as? Data)?.base64EncodedString() ?? ""
        case .array, .dictionary:
            jsonText(for: value)
        }
    }

    static func parse(_ text: String, as kind: PlistValueKind) throws -> Any {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        switch kind {
        case .string:
            return text
        case .integer:
            guard let value = Int64(trimmed) else {
                throw PlistValueError.invalid("Invalid integer")
            }
            return NSNumber(value: value)
        case .float:
            guard let value = Double(trimmed) else {
                throw PlistValueError.invalid("Invalid floating-point number")
            }
            return NSNumber(value: value)
        case .boolean:
            switch trimmed.lowercased() {
            case "true", "1", "yes":
                return NSNumber(value: true)
            case "false", "0", "no":
                return NSNumber(value: false)
            default:
                throw PlistValueError.invalid("Enter true or false")
            }
        case .data:
            guard let data = Data(base64Encoded: trimmed) else {
                throw PlistValueError.invalid("Invalid Base64 data")
            }
            return data
        case .array:
            return try jsonObject(from: trimmed, expected: NSArray.self)
        case .dictionary:
            return try jsonObject(from: trimmed, expected: NSDictionary.self)
        }
    }

    private static func jsonText(for value: Any?) -> String {
        guard let value,
              JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(
                withJSONObject: value,
                options: [.prettyPrinted, .sortedKeys]
              ) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func jsonObject<T>(from text: String, expected: T.Type) throws -> Any {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              object is T else {
            throw PlistValueError.invalid("Invalid JSON \(T.self)")
        }
        return object
    }
}

enum PlistValueError: LocalizedError {
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let message): message
        }
    }
}

struct GestaltPlist {
    var dict: [String: Any]

    var topLevelKeys: [String] {
        dict.keys.sorted()
    }

    var cacheExtra: [String: Any] {
        get { dict["CacheExtra"] as? [String: Any] ?? [:] }
        set { dict["CacheExtra"] = newValue }
    }

    var cacheExtraKeys: [String] {
        cacheExtra.keys.sorted()
    }

    func value(forKey key: String) -> Any? {
        dict[key]
    }

    mutating func setValue(_ value: Any, forKey key: String) {
        dict[key] = value
    }

    mutating func setCacheExtra(_ value: Any, forKey key: String) {
        var values = cacheExtra
        values[key] = value
        cacheExtra = values
    }

    mutating func removeCacheExtraValue(forKey key: String) {
        var values = cacheExtra
        values.removeValue(forKey: key)
        cacheExtra = values
    }
}
