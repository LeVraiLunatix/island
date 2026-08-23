import Foundation
import UIKit
import ZIPFoundation

enum CustomWallpaperBuilderError: LocalizedError {
    case imageEncodingFailed
    case fileOperationFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            "Impossible de préparer cette photo (format d'image non pris en charge)."
        case .fileOperationFailed(let detail):
            "Écriture impossible : \(detail)"
        }
    }
}

/// Assembles a PosterBoard descriptor bundle from an arbitrary photo, using
/// CustomWallpaperTemplate's verified skeleton. See that file for how this
/// was reverse-engineered from real, working community wallpapers.
enum CustomWallpaperBuilder {
    /// Builds a fresh descriptor folder tree under a temporary directory and
    /// returns the *parent* "descriptors" folder -- the shape
    /// PosterBoardInstaller expects to copy from, matching how a real
    /// .tendies unzips (a top-level "descriptors" folder directly
    /// containing one descriptor-UUID folder per wallpaper).
    static func buildDescriptorsFolder(from image: UIImage) throws -> URL {
        guard let jpegData = croppedJPEGData(from: image) else {
            throw CustomWallpaperBuilderError.imageEncodingFailed
        }

        let fm = FileManager.default
        let workingRoot = fm.temporaryDirectory
            .appendingPathComponent("IslandCustomWallpaper", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let descriptorsDir = workingRoot.appendingPathComponent("descriptors", isDirectory: true)
        let descriptorDir = descriptorsDir.appendingPathComponent(UUID().uuidString, isDirectory: true)

        do {
            try fm.createDirectory(at: descriptorDir, withIntermediateDirectories: true)

            try write("0", to: descriptorDir.appendingPathComponent("com.apple.posterkit.provider.descriptor.identifier"))
            try write(CustomWallpaperTemplate.roleIdentifier, to: descriptorDir.appendingPathComponent("com.apple.posterkit.role.identifier"))
            try writeBase64(CustomWallpaperTemplate.suggestionMetadataPlistBase64, to: descriptorDir.appendingPathComponent("com.apple.posterkit.provider.identifierURL.suggestionMetadata.plist"))
            try writeBase64(CustomWallpaperTemplate.providerInfoPlistBase64, to: descriptorDir.appendingPathComponent("providerInfo.plist"))

            let versionDir = descriptorDir.appendingPathComponent("versions/1", isDirectory: true)
            try fm.createDirectory(at: versionDir, withIntermediateDirectories: true)
            try writeBase64(CustomWallpaperTemplate.runtimeSnapshotHomePlistBase64, to: versionDir.appendingPathComponent("RuntimeSnapshotMetadata-home.plist"))
            try writeBase64(CustomWallpaperTemplate.runtimeSnapshotLockPlistBase64, to: versionDir.appendingPathComponent("RuntimeSnapshotMetadata-lock.plist"))
            try writeBase64(CustomWallpaperTemplate.complicationLayoutPlistBase64, to: versionDir.appendingPathComponent("com.apple.posterkit.provider.instance.complicationLayout.plist"))
            try writeBase64(CustomWallpaperTemplate.titleStyleConfigurationPlistBase64, to: versionDir.appendingPathComponent("com.apple.posterkit.provider.instance.titleStyleConfiguration.plist"))

            let contentsDir = versionDir.appendingPathComponent("contents", isDirectory: true)
            try fm.createDirectory(at: contentsDir, withIntermediateDirectories: true)
            try writeBase64(CustomWallpaperTemplate.configurableOptionsPlistBase64, to: contentsDir.appendingPathComponent(".com.apple.posterkit.provider.contents.configurableOptions.plist"))
            try writeBase64(CustomWallpaperTemplate.otherMetadataPlistBase64, to: contentsDir.appendingPathComponent("com.apple.posterkit.provider.contents.otherMetadata.plist"))
            try writeBase64(CustomWallpaperTemplate.userInfoPlistBase64, to: contentsDir.appendingPathComponent("com.apple.posterkit.provider.contents.userInfo"))

            let wallpaperDir = contentsDir.appendingPathComponent(CustomWallpaperTemplate.wallpaperFolderName, isDirectory: true)
            try fm.createDirectory(at: wallpaperDir, withIntermediateDirectories: true)
            try writeBase64(CustomWallpaperTemplate.wallpaperPlistBase64, to: wallpaperDir.appendingPathComponent("Wallpaper.plist"))

            let backgroundDir = wallpaperDir.appendingPathComponent(CustomWallpaperTemplate.backgroundCAName, isDirectory: true)
            let assetsDir = backgroundDir.appendingPathComponent("assets", isDirectory: true)
            try fm.createDirectory(at: assetsDir, withIntermediateDirectories: true)
            try write(CustomWallpaperTemplate.assetManifest, to: backgroundDir.appendingPathComponent("assetManifest.caml"))
            try write(CustomWallpaperTemplate.indexXML, to: backgroundDir.appendingPathComponent("index.xml"))
            try write(CustomWallpaperTemplate.imageLayerCAML(imageFileName: "photo.jpg"), to: backgroundDir.appendingPathComponent("main.caml"))
            try jpegData.write(to: assetsDir.appendingPathComponent("photo.jpg"), options: .atomic)

            for caName in [CustomWallpaperTemplate.floatingCAName, CustomWallpaperTemplate.foregroundCAName] {
                let dir = wallpaperDir.appendingPathComponent(caName, isDirectory: true)
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                try write(CustomWallpaperTemplate.assetManifest, to: dir.appendingPathComponent("assetManifest.caml"))
                try write(CustomWallpaperTemplate.indexXML, to: dir.appendingPathComponent("index.xml"))
                try write(CustomWallpaperTemplate.emptyLayerCAML, to: dir.appendingPathComponent("main.caml"))
            }

            let supplementsDir = versionDir.appendingPathComponent("supplements/0", isDirectory: true)
            try fm.createDirectory(at: supplementsDir, withIntermediateDirectories: true)
            try writeBase64(CustomWallpaperTemplate.homescreenConfigurationPlistBase64, to: supplementsDir.appendingPathComponent("com.apple.posterkit.provider.supplementURL.homescreenConfiguration.plist"))
        } catch let error as CustomWallpaperBuilderError {
            throw error
        } catch {
            throw CustomWallpaperBuilderError.fileOperationFailed(error.localizedDescription)
        }

        return descriptorsDir
    }

    /// Zips `descriptorsFolder` (the "descriptors" directory itself) into a
    /// .tendies archive whose top-level entry is "descriptors/<uuid>/...",
    /// matching the real Cowabunga catalog's own layout exactly.
    static func exportTendies(descriptorsFolder: URL, name: String) throws -> URL {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = trimmedName.isEmpty ? "Wallpaper" : trimmedName
            .components(separatedBy: CharacterSet(charactersIn: "/\\:*?\"<>|").inverted)
            .joined()
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName.isEmpty ? "Wallpaper" : safeName).tendies")
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.zipItem(at: descriptorsFolder, to: destination, shouldKeepParent: true)
        } catch {
            throw CustomWallpaperBuilderError.fileOperationFailed(error.localizedDescription)
        }
        return destination
    }

    /// Center-crops `image` to CustomWallpaperTemplate.canvasSize's aspect
    /// ratio and renders it at CustomWallpaperTemplate.renderScale, so the
    /// resulting JPEG can be referenced by a CALayer sized to exactly match
    /// the canvas with no distortion or letterboxing.
    private static func croppedJPEGData(from image: UIImage) -> Data? {
        let canvas = CustomWallpaperTemplate.canvasSize
        let scale = CustomWallpaperTemplate.renderScale
        let targetPixelSize = CGSize(width: canvas.width * scale, height: canvas.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetPixelSize, format: format)

        let rendered = renderer.image { _ in
            let sourceSize = image.size
            guard sourceSize.width > 0, sourceSize.height > 0 else { return }

            let targetAspect = targetPixelSize.width / targetPixelSize.height
            let sourceAspect = sourceSize.width / sourceSize.height

            var drawSize = targetPixelSize
            if sourceAspect > targetAspect {
                drawSize.width = targetPixelSize.height * sourceAspect
            } else {
                drawSize.height = targetPixelSize.width / sourceAspect
            }
            let origin = CGPoint(
                x: (targetPixelSize.width - drawSize.width) / 2,
                y: (targetPixelSize.height - drawSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }

        return rendered.jpegData(compressionQuality: 0.92)
    }

    private static func write(_ string: String, to url: URL) throws {
        guard let data = string.data(using: .utf8) else {
            throw CustomWallpaperBuilderError.fileOperationFailed("Encodage texte impossible.")
        }
        try data.write(to: url, options: .atomic)
    }

    private static func writeBase64(_ base64: String, to url: URL) throws {
        try CustomWallpaperTemplate.data(fromBase64: base64).write(to: url, options: .atomic)
    }
}
