import Combine
import Foundation

@MainActor
final class GestaltViewModel: ObservableObject {
    @Published var plist: GestaltPlist?
    @Published var isBusy = false
    @Published var notice: GestaltNotice?
    @Published private(set) var hasAttemptedLoad = false
    @Published var dynamicIslandSubtype: Int = DynamicIslandOption.all[0].subtype
    @Published private(set) var isRespringing = false

    private let access = GestaltAccess.shared()

    func load() {
        guard !isBusy else { return }
        hasAttemptedLoad = true
        isBusy = true
        notice = nil

        defer { isBusy = false }
        do {
            try access.connect()
            guard let dictionary = try access.readGestalt() as? [String: Any] else {
                throw IslandError.invalidPlist
            }
            plist = GestaltPlist(dict: dictionary)
        } catch {
            plist = nil
            report(error)
        }
    }

    func applySelectedTweaks() {
        guard !isBusy, var pending = plist else { return }
        do {
            pending.apply(definition: GestaltTweakCatalog.supportsDynamicIsland)
            try pending.setDynamicIslandSubtype(dynamicIslandSubtype)
            save(pending)
        } catch {
            report(error)
        }
    }

    private func save(_ pendingPlist: GestaltPlist) {
        isBusy = true
        notice = nil

        do {
            let originalData = try access.readGestaltData()
            _ = try GestaltBackupStore.create(from: originalData)
            try access.saveGestalt(pendingPlist.dict)
            guard let verification = try access.readGestalt() as? [String: Any] else {
                throw IslandError.invalidPlist
            }
            plist = GestaltPlist(dict: verification)
            isBusy = false
            isRespringing = true
        } catch {
            report(error)
            isBusy = false
        }
    }

    private func report(_ error: Error) {
        notice = GestaltNotice(kind: .error, message: error.localizedDescription)
    }
}

private enum IslandError: LocalizedError {
    case invalidPlist

    var errorDescription: String? {
        switch self {
        case .invalidPlist: String(localized: "The MobileGestalt plist is not a valid dictionary.")
        }
    }
}
