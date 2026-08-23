import Combine
import Foundation

struct Wallpaper: Identifiable, Decodable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let url: String
    let preview: String
    let authors: String?
    let contest: String?

    private static let githubBase = "https://raw.githubusercontent.com/SerStars/nugget-wallpapers/main/"

    var downloadURL: URL? {
        URL(string: url.hasPrefix("https://") ? url : Self.githubBase + url)
    }

    var previewURL: URL? {
        URL(string: preview.hasPrefix("https://") ? preview : Self.githubBase + preview)
    }

    /// Hands the download off to the Pocket Poster app, which performs the
    /// actual on-device wallpaper installation. Island does not write
    /// SpringBoard wallpaper data itself.
    var pocketPosterURL: URL? {
        guard let downloadURL,
              let encoded = downloadURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "pocketposter://download?url=\(encoded)")
    }
}

enum WallpaperCategory: String, CaseIterable, Identifiable {
    case custom
    case apple
    case template

    var id: String { rawValue }

    var label: String {
        switch self {
        case .custom: "Personnalisés"
        case .apple: "Apple"
        case .template: "Modèles"
        }
    }

    fileprivate var jsonFileName: String {
        switch self {
        case .custom: "wallpapers-custom.json"
        case .apple: "wallpapers-apple.json"
        case .template: "wallpapers-template.json"
        }
    }
}

@MainActor
final class WallpaperCatalogLoader: ObservableObject {
    @Published private(set) var wallpapers: [WallpaperCategory: [Wallpaper]] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private static let base = URL(string: "https://raw.githubusercontent.com/SerStars/nugget-wallpapers/main/")!

    func load(_ category: WallpaperCategory) async {
        guard wallpapers[category] == nil else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let url = Self.base.appendingPathComponent(category.jsonFileName)
            let (data, _) = try await URLSession.shared.data(from: url)
            wallpapers[category] = try JSONDecoder().decode([Wallpaper].self, from: data)
        } catch {
            errorMessage = "Impossible de charger la bibliothèque : \(error.localizedDescription)"
        }
    }
}
