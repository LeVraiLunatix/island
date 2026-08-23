import Foundation

struct GestaltPlist {
    var dict: [String: Any]

    var cacheExtra: [String: Any] {
        get { dict["CacheExtra"] as? [String: Any] ?? [:] }
        set { dict["CacheExtra"] = newValue }
    }

    mutating func setCacheExtra(_ value: Any, forKey key: String) {
        var values = cacheExtra
        values[key] = value
        cacheExtra = values
    }
}

struct GestaltNotice: Identifiable {
    enum Kind { case error, backupCreated, riskWarning }

    let id = UUID()
    let kind: Kind
    let message: String

    var title: String {
        switch kind {
        case .error: String(localized: "Operation Failed")
        case .backupCreated: String(localized: "Backup Complete")
        case .riskWarning: String(localized: "High Risk")
        }
    }
}

struct DynamicIslandOption: Identifiable, Hashable {
    let subtype: Int
    let title: String
    var id: Int { subtype }

    static let all: [DynamicIslandOption] = [
        .init(subtype: 2556, title: "iPhone 14 Pro"),
        .init(subtype: 2796, title: "iPhone 14 Pro Max"),
        .init(subtype: 2622, title: "iPhone 16 Pro"),
        .init(subtype: 2868, title: "iPhone 16 Pro Max"),
        .init(subtype: 2736, title: "iPhone Air")
    ]
}
