import Foundation
import UIKit

enum ExploitBackend: String {
    case badQuery
    case nuggetBackup
    case unsupported
}

struct VersionRouter {
    private static let beta1to4BuildPrefixes = [
        "23A5257",
        "23A5267",
        "23A5276",
        "23A5287"
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

    static func systemVersionComponents() -> (Int, Int, Int) {
        let v = UIDevice.current.systemVersion
        let parts = v.split(separator: ".").compactMap { Int($0) }
        let major = parts.count > 0 ? parts[0] : 0
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0
        return (major, minor, patch)
    }

    static func pick() -> ExploitBackend {
        let (major, _, _) = systemVersionComponents()
        guard major == 27 else { return .unsupported }

        if isBeta1to4Build() {
            let w = BadQueryWriter()
            return w.isAvailable() ? .badQuery : .nuggetBackup
        }

        let w = NuggetBackupWriter()
        return w.isAvailable() ? .nuggetBackup : .unsupported
    }

    static func writer() -> GestaltWriter? {
        switch pick() {
        case .badQuery:     return BadQueryWriter()
        case .nuggetBackup: return NuggetBackupWriter()
        case .unsupported:  return nil
        }
    }

    static func humanBackendLabel() -> String {
        switch pick() {
        case .badQuery:     return "bad_query (iOS 27 beta 1-4)"
        case .nuggetBackup: return "Pocket Poster bridge (iOS 27.0.1+)"
        case .unsupported:  return "Non supporté"
        }
    }
}
