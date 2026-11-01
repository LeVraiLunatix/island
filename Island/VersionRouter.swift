import Foundation
import UIKit

/// Détecte la version iOS et dit si le Nugget/PocketPoster backend s'applique.
/// Ne touche PAS au backend historique du fork (bad_query path), qui reste
/// la route par défaut sur beta 1-4 via le code existant.
enum IslandBackend: String {
    case legacyBadQuery   // code existant du fork, pour beta 1-4
    case nuggetBackup     // route Pocket Poster, pour 27.0.1+
    case unsupported
}

struct VersionRouter {
    private static let beta1to4BuildPrefixes = [
        "23A5257", "23A5267", "23A5276", "23A5287"
    ]

    static func currentBuild() -> String {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var raw = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &raw, &size, nil, 0)
        return String(cString: raw)
    }

    static func isBeta1to4Build() -> Bool {
        let b = currentBuild()
        return beta1to4BuildPrefixes.contains { b.hasPrefix($0) }
    }

    static func systemMajor() -> Int {
        let v = UIDevice.current.systemVersion
        return Int(v.split(separator: ".").first.map(String.init) ?? "0") ?? 0
    }

    static func pick() -> IslandBackend {
        guard systemMajor() == 27 else { return .unsupported }
        if isBeta1to4Build() { return .legacyBadQuery }
        return .nuggetBackup
    }

    static func nuggetWriter() -> GestaltWriter {
        return NuggetBackupWriter()
    }

    static func humanLabel() -> String {
        switch pick() {
        case .legacyBadQuery: return "bad_query (iOS 27 beta 1-4)"
        case .nuggetBackup:   return "Pocket Poster (iOS 27.0.1+)"
        case .unsupported:    return "Non supporté"
        }
    }

    static func pocketPosterInstalled() -> Bool {
        guard let u = URL(string: "pocketposter://") else { return false }
        return UIApplication.shared.canOpenURL(u)
    }
}
