import Combine
import Foundation
import ZIPFoundation

enum PosterBoardError: LocalizedError {
    case missingAppHash
    case invalidTendie
    case noDescriptorsFound
    case sandboxExtensionFailed(String)
    case destinationMissing
    case nothingCopied
    case fileOperationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAppHash:
            "Renseigne d'abord le hash de conteneur PosterBoard dans les réglages."
        case .invalidTendie:
            "Ce fichier .tendies est invalide ou dans un format non pris en charge."
        case .noDescriptorsFound:
            "Aucun descripteur trouvé dans ce fichier .tendies après extraction — la structure ne correspond pas à ce qu'Island attend."
        case .sandboxExtensionFailed(let detail):
            "bad_query n'a pas pu accéder au conteneur de PosterBoard : \(detail)"
        case .destinationMissing:
            "Dossier introuvable dans le conteneur PosterBoard. Ouvre d'abord Réglages > Fond d'écran sur ton iPhone pour que PosterBoard crée sa structure, ou vérifie que le hash renseigné est correct."
        case .nothingCopied:
            "Le dossier de descripteurs de ce .tendies était vide : rien n'a été copié."
        case .fileOperationFailed(let detail):
            "Écriture impossible : \(detail)"
        }
    }
}

struct PosterBoardInstallResult {
    let copiedItemNames: [String]
    let destinationPaths: [String]
}

/// Installs a Cowabunga .tendies wallpaper package directly into PosterBoard's
/// private container, using Island's existing bad_query sandbox-extension
/// primitive instead of Pocket Poster's separate .Trash-symlink trick.
///
/// The descriptor discovery and wallpaper-ID randomization logic below is
/// ported from leminlimez/Pocket-Poster (GPL-3.0), the reference
/// implementation for this private PosterBoard layout.
@MainActor
final class PosterBoardInstaller: ObservableObject {
    @Published private(set) var isInstalling = false
    @Published private(set) var progressMessage: String?

    private static let extensionVersion = "61"

    @discardableResult
    func install(wallpaper: Wallpaper) async throws -> PosterBoardInstallResult {
        let appHash = PosterBoardHashStore.hash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appHash.isEmpty else { throw PosterBoardError.missingAppHash }
        guard let downloadURL = wallpaper.downloadURL else { throw PosterBoardError.invalidTendie }

        isInstalling = true
        defer {
            isInstalling = false
            progressMessage = nil
        }

        progressMessage = "Téléchargement…"
        let (tendieData, _) = try await URLSession.shared.data(from: downloadURL)

        progressMessage = "Extraction…"
        let unzippedDir = try Self.unzip(tendieData)
        defer { try? FileManager.default.removeItem(at: unzippedDir) }

        guard let descriptors = try Self.descriptors(in: unzippedDir), !descriptors.isEmpty else {
            throw PosterBoardError.noDescriptorsFound
        }

        progressMessage = "Installation dans PosterBoard…"
        var copiedNames: [String] = []
        var destinationPaths: [String] = []
        for (extensionID, descriptorDirs) in descriptors {
            for descriptorDir in descriptorDirs {
                let (names, destination) = try Self.install(descriptorDir: descriptorDir, extensionID: extensionID, appHash: appHash)
                copiedNames.append(contentsOf: names)
                destinationPaths.append(destination)
            }
        }

        guard !copiedNames.isEmpty else {
            throw PosterBoardError.nothingCopied
        }

        return PosterBoardInstallResult(copiedItemNames: copiedNames, destinationPaths: destinationPaths)
    }

    /// Installs a descriptor bundle built on-device (see
    /// CustomWallpaperBuilder) rather than downloaded as a .tendies.
    /// `descriptorsFolder` must be a "descriptors" directory directly
    /// containing one descriptor-UUID folder, the same shape a flat
    /// .tendies unzips to.
    @discardableResult
    func installCustomDescriptors(at descriptorsFolder: URL) async throws -> PosterBoardInstallResult {
        let appHash = PosterBoardHashStore.hash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appHash.isEmpty else { throw PosterBoardError.missingAppHash }

        isInstalling = true
        defer {
            isInstalling = false
            progressMessage = nil
        }

        progressMessage = "Installation dans PosterBoard…"
        let (names, destination) = try Self.install(
            descriptorDir: descriptorsFolder,
            extensionID: "com.apple.WallpaperKit.CollectionsPoster",
            appHash: appHash
        )
        guard !names.isEmpty else { throw PosterBoardError.nothingCopied }
        return PosterBoardInstallResult(copiedItemNames: names, destinationPaths: [destination])
    }

    // MARK: - Unzip

    private static func unzip(_ data: Data) throws -> URL {
        let stagingRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("IslandTendies", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: stagingRoot, withIntermediateDirectories: true)

        let zipURL = stagingRoot.appendingPathComponent("wallpaper.tendies")
        try data.write(to: zipURL, options: .atomic)

        let destination = stagingRoot.appendingPathComponent("unzipped", isDirectory: true)
        do {
            try FileManager.default.unzipItem(at: zipURL, to: destination)
        } catch {
            throw PosterBoardError.invalidTendie
        }
        return destination
    }

    // MARK: - Descriptor discovery (ported from Pocket-Poster, GPL-3.0)

    private static func descriptors(in url: URL) throws -> [String: [URL]]? {
        for entry in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            switch entry.lastPathComponent.lowercased() {
            case "container":
                let extensionsDir = entry.appendingPathComponent("Library/Application Support/PRBPosterExtensionDataStore/\(extensionVersion)/Extensions")
                guard FileManager.default.fileExists(atPath: extensionsDir.path) else { continue }
                var result: [String: [URL]] = [:]
                for ext in try FileManager.default.contentsOfDirectory(at: extensionsDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                    result[ext.lastPathComponent] = [ext.appendingPathComponent("descriptors")]
                }
                return result
            case "descriptor", "descriptors", "ordered-descriptor", "ordered-descriptors":
                return ["com.apple.WallpaperKit.CollectionsPoster": [entry]]
            case "video-descriptor", "video-descriptors":
                return ["com.apple.PhotosUIPrivate.PhotosPosterProvider": [entry]]
            default:
                continue
            }
        }
        return nil
    }

    private static func randomizeWallpaperID(at url: URL) {
        let randomID = Int.random(in: 9999...99999)
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        func setPlistValue(atPath path: String, key: String, value: Any) {
            guard let data = FileManager.default.contents(atPath: path),
                  var plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                return
            }
            plist[key] = value
            guard let updated = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else { return }
            try? updated.write(to: URL(fileURLWithPath: path))
        }

        for case let fileURL as URL in enumerator {
            switch fileURL.lastPathComponent {
            case "com.apple.posterkit.provider.descriptor.identifier":
                try? String(randomID).data(using: .utf8)?.write(to: fileURL)
            case "com.apple.posterkit.provider.contents.userInfo":
                setPlistValue(atPath: fileURL.path, key: "wallpaperRepresentingIdentifier", value: randomID)
            case "Wallpaper.plist":
                setPlistValue(atPath: fileURL.path, key: "identifier", value: randomID)
            default:
                continue
            }
        }
    }

    // MARK: - Privileged write via bad_query

    private static func install(descriptorDir: URL, extensionID: String, appHash: String) throws -> (names: [String], destination: String) {
        let destinationRoot = "/var/mobile/Containers/Data/Application/\(appHash)/Library/Application Support/PRBPosterExtensionDataStore/\(extensionVersion)/Extensions/\(extensionID)/descriptors"

        var leaseError: NSString?
        guard let lease = BadQueryLeaseHelper.acquireLease(path: destinationRoot, errorMessage: &leaseError) else {
            throw PosterBoardError.sandboxExtensionFailed((leaseError as String?) ?? "raison inconnue")
        }
        defer { lease.invalidate() }

        guard FileManager.default.fileExists(atPath: destinationRoot) else {
            throw PosterBoardError.destinationMissing
        }

        guard FileManager.default.fileExists(atPath: descriptorDir.path) else {
            throw PosterBoardError.noDescriptorsFound
        }

        var copiedNames: [String] = []
        for entry in try FileManager.default.contentsOfDirectory(at: descriptorDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            guard entry.lastPathComponent != "__MACOSX" else { continue }
            randomizeWallpaperID(at: entry)

            let destination = URL(fileURLWithPath: destinationRoot).appendingPathComponent(entry.lastPathComponent)
            if FileManager.default.fileExists(atPath: destination.path) {
                try? FileManager.default.removeItem(at: destination)
            }
            do {
                try FileManager.default.copyItem(at: entry, to: destination)
                copiedNames.append(entry.lastPathComponent)
            } catch {
                throw PosterBoardError.fileOperationFailed(error.localizedDescription)
            }
        }

        return (copiedNames, destinationRoot)
    }
}
