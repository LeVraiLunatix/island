import SwiftUI
import UIKit

struct WallpapersView: View {
    @StateObject private var loader = WallpaperCatalogLoader()
    @State private var category: WallpaperCategory = .custom
    @State private var selectedWallpaper: Wallpaper?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        VStack(spacing: 0) {
            Picker("Catégorie", selection: $category) {
                ForEach(WallpaperCategory.allCases) { category in
                    Text(category.label).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView {
                content
                    .padding(16)
            }
        }
        .background(Color.black)
        .navigationTitle("Fonds d'écran")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: category) { await loader.load(category) }
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailSheet(wallpaper: wallpaper)
        }
    }

    @ViewBuilder
    private var content: some View {
        let items = loader.wallpapers[category] ?? []

        if items.isEmpty, loader.isLoading {
            ProgressView("Chargement…")
                .tint(.white)
                .foregroundStyle(.white)
                .padding(.top, 60)
        } else if items.isEmpty, let message = loader.errorMessage {
            VStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.5))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 24)
        } else {
            GlassEffectContainer(spacing: 14) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(items) { wallpaper in
                        Button {
                            selectedWallpaper = wallpaper
                        } label: {
                            WallpaperThumbnail(wallpaper: wallpaper)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct WallpaperThumbnail: View {
    let wallpaper: Wallpaper

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: wallpaper.previewURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(Color.white.opacity(0.08))
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .clipped()

                if let contest = wallpaper.contest {
                    Text(contest)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(.regular, in: Capsule())
                        .padding(6)
                }
            }

            Text(wallpaper.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if let authors = wallpaper.authors {
                Text(authors)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(10)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct WallpaperDetailSheet: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) private var dismiss
    @State private var pocketPosterFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AsyncImage(url: wallpaper.previewURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFit()
                        } else {
                            Rectangle().fill(Color.white.opacity(0.08))
                                .frame(height: 240)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.horizontal, 20)

                    VStack(spacing: 6) {
                        Text(wallpaper.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        if let description = wallpaper.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                        }
                        if let authors = wallpaper.authors {
                            Text("Créé par \(authors)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button {
                            openInPocketPoster()
                        } label: {
                            Label("Ouvrir dans Pocket Poster", systemImage: "square.and.arrow.down.on.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)

                        Button {
                            openDownload()
                        } label: {
                            Label("Télécharger le fichier .tendies", systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)

                        if pocketPosterFailed {
                            Text("Pocket Poster ne semble pas installé. Installe-le depuis son dépôt, ou télécharge le fichier .tendies et importe-le manuellement.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func openInPocketPoster() {
        guard let url = wallpaper.pocketPosterURL else { return }
        pocketPosterFailed = false
        UIApplication.shared.open(url, options: [:]) { success in
            pocketPosterFailed = !success
        }
    }

    private func openDownload() {
        guard let url = wallpaper.downloadURL else { return }
        UIApplication.shared.open(url)
    }
}
