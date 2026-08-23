import Foundation

enum GestaltTweakCategory: String, CaseIterable, Identifiable {
    case display
    case hardware
    case ipad
    case internalFeatures

    var id: String { rawValue }

    var label: String {
        switch self {
        case .display: "Affichage"
        case .hardware: "Matériel"
        case .ipad: "Fonctions iPad"
        case .internalFeatures: "Interne & Recherche"
        }
    }
}

enum GestaltTweakID: String, CaseIterable, Identifiable {
    case bootChime
    case chargeLimit
    case tapToWake
    case cameraButton
    case disableParallax
    case enableLiquidGlassLowPerformance
    case disableLiquidGlassLowPerformance
    case stageManager
    case iPadOS
    case iPadApps
    case pencil
    case actionButton
    case internalInstall
    case internalStorage
    case securityResearchDevice
    case collisionSOS
    case alwaysOnDisplay
    case alwaysOnDisplayVibrancy

    var id: String { rawValue }
}

struct GestaltTweakDefinition: Identifiable {
    let id: GestaltTweakID
    let category: GestaltTweakCategory
    let title: String
    let detail: String
    let values: [String: Any]
    var isRisky = false
}

enum GestaltTweakCatalog {
    static let definitions: [GestaltTweakDefinition] = [
        .init(id: .alwaysOnDisplay, category: .display, title: "Écran Always-On", detail: "Peut augmenter le risque de rémanence sur les appareils non pris en charge.", values: ["2OOJf1VhaM7NxfRok3HbWQ": 1, "j8/Omm6s1lsmTDFsXjsBfA": 1], isRisky: true),
        .init(id: .alwaysOnDisplayVibrancy, category: .display, title: "Vibrance AOD", detail: "À utiliser si le rendu de l'écran Always-On semble incorrect.", values: ["ykpu7qyhqFweVMKtxNylWA": 1]),
        .init(id: .disableParallax, category: .display, title: "Désactiver le parallaxe du fond d'écran", detail: "Arrête le mouvement du fond d'écran basé sur les mouvements de l'appareil.", values: ["UIParallaxCapability": 0]),
        .init(id: .enableLiquidGlassLowPerformance, category: .display, title: "Activer Liquid Glass (mode basse perf.)", detail: "Pour iOS 26 et versions ultérieures.", values: ["SAGvsp6O6kAQ4fEfDJpC4Q": 1]),
        .init(id: .disableLiquidGlassLowPerformance, category: .display, title: "Désactiver Liquid Glass (mode basse perf.)", detail: "Mutuellement exclusif avec l'option ci-dessus.", values: ["SAGvsp6O6kAQ4fEfDJpC4Q": 0]),

        .init(id: .bootChime, category: .hardware, title: "Son de démarrage/extinction", detail: "Active la capacité de son au démarrage et à l'extinction.", values: ["QHxt+hGLaBPbQJbXiUJX3w": 1]),
        .init(id: .chargeLimit, category: .hardware, title: "Menu de limite de charge", detail: "Affiche le menu dans Réglages ; la limitation réelle dépend du matériel.", values: ["37NVydb//GP/GrhuTN+exg": 1]),
        .init(id: .tapToWake, category: .hardware, title: "Tap to Wake", detail: "Principalement pour des modèles comme l'iPhone SE où c'est indisponible.", values: ["yZf3GTRMGTuwSV/lD7Cagw": 1]),
        .init(id: .cameraButton, category: .hardware, title: "Réglages Camera Control (iPhone 16)", detail: "Affiche les réglages Camera Control et les fonctions associées.", values: ["CwvKxM2cEogD3p+HYgaW0Q": 1, "oOV1jhJbdV3AddkcCg0AEA": 1]),
        .init(id: .pencil, category: .hardware, title: "Réglages Apple Pencil", detail: "Affiche la page de réglages Apple Pencil.", values: ["yhHcB0iH0d1XzPO/CFd3ow": 1]),
        .init(id: .actionButton, category: .hardware, title: "Réglages du bouton Action", detail: "Affiche la page de réglages du bouton Action.", values: ["cT44WE1EohiwRzhsZ8xEsw": 1]),
        .init(id: .collisionSOS, category: .hardware, title: "Détection de collision", detail: "Affiche la détection de collision dans les réglages SOS.", values: ["HCzWusHQwZDea6nNhaKndw": 1]),

        .init(id: .stageManager, category: .ipad, title: "Support du Stage Manager", detail: "Marque l'appareil comme compatible avec le Stage Manager.", values: ["qeaj75wk3HF4DwQ8qbIi7g": 1]),
        .init(id: .iPadApps, category: .ipad, title: "Autoriser les apps iPad", detail: "Active les types de compatibilité des apps iPad sur iPhone.", values: ["9MZ5AdH43csAUajl/dU+IQ": [1, 2]]),
        .init(id: .iPadOS, category: .ipad, title: "Activer le mode iPadOS", detail: "Modifie cinq capacités et CacheData ; expérimental et à haut risque.", values: ["mG0AnH/Vy1veoqoLRAIgTA": 1, "UCG5MkVahJxG1YULbbd5Bg": 1, "ZYqko/XM5zD3XBfN5RmaXA": 1, "nVh/gwNpy7Jv1NOk00CMrw": 1, "uKc7FPnEO++lVhHWHFlGbQ": 1], isRisky: true),

        .init(id: .internalInstall, category: .internalFeatures, title: "Apple Internal Install", detail: "Active des fonctions internes comme le Metal HUD ; certains services peuvent mal fonctionner.", values: ["EqrsVvjcYDdxHBiQmGhAWw": 1], isRisky: true),
        .init(id: .internalStorage, category: .internalFeatures, title: "Affichage du stockage interne", detail: "Affiche les fichiers internes dans Réglages > Stockage ; haut risque sur certains iPad.", values: ["LBJfwOEzExRxzlAnSuI7eg": 1], isRisky: true),
        .init(id: .securityResearchDevice, category: .internalFeatures, title: "Mode Security Research Device", detail: "Marque l'appareil comme Security Research Device.", values: ["XYlJKKkj2hztRP1NWWnhlw": 1], isRisky: true)
    ]

    static func definition(for id: GestaltTweakID) -> GestaltTweakDefinition? {
        definitions.first { $0.id == id }
    }
}

enum GestaltTweakError: LocalizedError {
    case artworkDictionaryMissing
    case cacheDataMissing
    case cacheDataTooShort
    case cacheDataPatternNotFound
    case invalidCacheDataOffset

    var errorDescription: String? {
        switch self {
        case .artworkDictionaryMissing: "MobileGestalt ne contient pas le dictionnaire ArtworkDevice : impossible de modifier la Dynamic Island ou le nom du modèle."
        case .cacheDataMissing: "MobileGestalt ne contient pas CacheData : impossible d'activer le mode iPadOS."
        case .cacheDataTooShort: "CacheData est trop court pour appliquer le mode iPadOS en toute sécurité."
        case .cacheDataPatternNotFound: "Le marqueur iPadOS requis par Nugget est introuvable dans CacheData."
        case .invalidCacheDataOffset: "La validation du marqueur CacheData a échoué. Aucune modification n'a été effectuée."
        }
    }
}

extension GestaltPlist {
    mutating func apply(definition: GestaltTweakDefinition) throws {
        for (key, value) in definition.values {
            setCacheExtra(value, forKey: key)
        }
        if definition.id == .iPadOS {
            try enableIPadOSCacheData()
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

    mutating func setModelName(_ name: String) throws {
        let key = "oPeik/9e8lQWMszEjbPzng"
        guard var artwork = cacheExtra[key] as? [String: Any] else {
            throw GestaltTweakError.artworkDictionaryMissing
        }
        artwork["ArtworkDeviceProductDescription"] = name
        setCacheExtra(artwork, forKey: key)
    }

    private static let artworkDeviceKey = "oPeik/9e8lQWMszEjbPzng"
    private static let dynamicIslandCompatibilityKey = "YlEtTtHlNesRBMal1CqRaA"
    private static let aiRegionOverrideKeys = [
        "A62OafQ85EJAiiqKn4agtg",
        "h9jDsbgj7xIVeIQ8S3/X3Q",
        "oYicEKzVTz4/CxxE05pEgQ",
        "5pYKlGnYYBzGvAlIU8RjEQ",
        "h63QSdBCiT/z0WU6rdQv6Q",
        "yK+xavymRGZ3xWc1tb8XDg",
        "97JDvERpVwO+GHtthIh7hA"
    ]

    /// Clears every MobileGestalt override Island's UI can write -- every
    /// capability preset, the Dynamic Island subtype/compatibility flag, the
    /// spoofed device name, and the Apple Intelligence region spoof -- and
    /// flips the iPadOS-mode CacheData bit back off if it was set. Works
    /// directly off the plist that's currently on-device, so unlike a
    /// backup restore it needs no prior state capture and still works after
    /// the app has been reinstalled.
    mutating func removeAllIslandOverrides() {
        var extra = cacheExtra
        for definition in GestaltTweakCatalog.definitions {
            for key in definition.values.keys {
                extra.removeValue(forKey: key)
            }
        }
        for key in Self.aiRegionOverrideKeys {
            extra.removeValue(forKey: key)
        }
        extra.removeValue(forKey: Self.dynamicIslandCompatibilityKey)
        cacheExtra = extra

        if var artwork = cacheExtra[Self.artworkDeviceKey] as? [String: Any] {
            artwork.removeValue(forKey: "ArtworkDeviceSubType")
            artwork.removeValue(forKey: "ArtworkDeviceProductDescription")
            setCacheExtra(artwork, forKey: Self.artworkDeviceKey)
        }

        disableIPadOSCacheDataIfNeeded()
    }

    /// Best-effort mirror of `enableIPadOSCacheData()`: flips the same bit
    /// back to its disabled value ("1") if -- and only if -- it currently
    /// reads as enabled ("3"). Silently does nothing if the marker can't be
    /// located or doesn't look like it was ever flipped, since this runs as
    /// part of a broad reset and must never throw or corrupt CacheData.
    private mutating func disableIPadOSCacheDataIfNeeded() {
        guard let cacheData = dict["CacheData"] as? Data else { return }
        var hex = Array(cacheData.map { String(format: "%02x", $0) }.joined())
        let sliceStart = 1616
        let sliceLength = 200
        guard hex.count > sliceStart else { return }

        let end = min(hex.count, sliceStart + sliceLength)
        let slice = String(hex[sliceStart..<end])
        guard let regex = try? NSRegularExpression(pattern: "0+(?:5555)*([0-9a-f]{4})") else { return }
        let nsRange = NSRange(slice.startIndex..<slice.endIndex, in: slice)
        var matchedOffset: Int?
        regex.enumerateMatches(in: slice, range: nsRange) { match, _, stop in
            guard let range = match.flatMap({ Range($0.range(at: 1), in: slice) }) else { return }
            let value = slice[range]
            if value.filter({ $0 != "0" }).count >= 3 {
                matchedOffset = sliceStart + slice.distance(from: slice.startIndex, to: range.lowerBound)
                stop.pointee = true
            }
        }
        guard let offset = matchedOffset else { return }

        let rightOffset = offset + 13
        let leftOffset = offset - 67
        guard leftOffset > 0, rightOffset < hex.count - 1 else { return }
        for position in [leftOffset, rightOffset] {
            guard ["1", "3"].contains(String(hex[position])),
                  hex[position - 1] == "0", hex[position + 1] == "0" else { return }
        }
        guard hex[leftOffset] == "3" else { return }

        hex[leftOffset] = "1"
        let updatedHex = String(hex)
        var updatedData = Data(capacity: updatedHex.count / 2)
        var index = updatedHex.startIndex
        while index < updatedHex.endIndex {
            let next = updatedHex.index(index, offsetBy: 2)
            guard let byte = UInt8(updatedHex[index..<next], radix: 16) else { return }
            updatedData.append(byte)
            index = next
        }
        dict["CacheData"] = updatedData
    }

    private mutating func enableIPadOSCacheData() throws {
        guard let cacheData = dict["CacheData"] as? Data else {
            throw GestaltTweakError.cacheDataMissing
        }
        var hex = Array(cacheData.map { String(format: "%02x", $0) }.joined())
        let sliceStart = 1616
        let sliceLength = 200
        guard hex.count > sliceStart else { throw GestaltTweakError.cacheDataTooShort }

        let end = min(hex.count, sliceStart + sliceLength)
        let slice = String(hex[sliceStart..<end])
        let regex = try NSRegularExpression(pattern: "0+(?:5555)*([0-9a-f]{4})")
        let nsRange = NSRange(slice.startIndex..<slice.endIndex, in: slice)
        var matchedOffset: Int?
        regex.enumerateMatches(in: slice, range: nsRange) { match, _, stop in
            guard let range = match.flatMap({ Range($0.range(at: 1), in: slice) }) else { return }
            let value = slice[range]
            if value.filter({ $0 != "0" }).count >= 3 {
                matchedOffset = sliceStart + slice.distance(from: slice.startIndex, to: range.lowerBound)
                stop.pointee = true
            }
        }
        guard let offset = matchedOffset else { throw GestaltTweakError.cacheDataPatternNotFound }

        let rightOffset = offset + 13
        let leftOffset = offset - 67
        guard leftOffset > 0, rightOffset < hex.count - 1 else {
            throw GestaltTweakError.invalidCacheDataOffset
        }
        for position in [leftOffset, rightOffset] {
            guard ["1", "3"].contains(String(hex[position])),
                  hex[position - 1] == "0", hex[position + 1] == "0" else {
                throw GestaltTweakError.invalidCacheDataOffset
            }
        }
        hex[leftOffset] = "3"
        let updatedHex = String(hex)
        var updatedData = Data(capacity: updatedHex.count / 2)
        var index = updatedHex.startIndex
        while index < updatedHex.endIndex {
            let next = updatedHex.index(index, offsetBy: 2)
            guard let byte = UInt8(updatedHex[index..<next], radix: 16) else {
                throw GestaltTweakError.invalidCacheDataOffset
            }
            updatedData.append(byte)
            index = next
        }
        dict["CacheData"] = updatedData
    }
}
