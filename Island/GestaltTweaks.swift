import Foundation

struct GestaltTweakDefinition {
    let title: String
    let detail: String
    let values: [String: Any]
}

enum GestaltTweakCatalog {
    static let supportsDynamicIsland = GestaltTweakDefinition(
        title: String(localized: "Enable Dynamic Island Capability"),
        detail: String(localized: "Nugget's alternate enable method."),
        values: ["YlEtTtHlNesRBMal1CqRaA": 1]
    )
}

enum GestaltTweakError: LocalizedError {
    case artworkDictionaryMissing

    var errorDescription: String? {
        switch self {
        case .artworkDictionaryMissing:
            String(localized: "MobileGestalt is missing the ArtworkDevice dictionary, so Dynamic Island cannot be changed.")
        }
    }
}

extension GestaltPlist {
    mutating func apply(definition: GestaltTweakDefinition) {
        for (key, value) in definition.values {
            setCacheExtra(value, forKey: key)
        }
    }

    mutating func setDynamicIslandSubtype(_ subtype: Int) throws {
        let key = "oPeik/9e8lQWMszEjbPzng"
        guard var artwork = cacheExtra[key] as? [String: Any] else {
            throw GestaltTweakError.artworkDictionaryMissing
        }
        artwork["ArtworkDeviceSubType"] = subtype
        setCacheExtra(artwork, forKey: key)
        setCacheExtra(1, forKey: "YlEtTtHlNesRBMal1CqRaA")
    }
}
