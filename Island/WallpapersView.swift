import SwiftUI
import UIKit

struct WallpapersView: View {
    @StateObject private var loader = WallpaperCatalogLoader()
    @State private var category: WallpaperCategory = .custom
    @State private var selectedWallpaper: Wallpaper?
    @State private var showsCreateWallpaper = false

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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showsCreateWallpaper = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task(id: category) { await loader.load(category) }
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailSheet(wallpaper: wallpaper)
        }
        .sheet(isPresented: $showsCreateWallpaper) {
            CreateWallpaperView()
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
    @StateObject private var installer = PosterBoardInstaller()
    @State private var pocketPosterFailed = false
    @State private var installError: String?
    @State private var installResult: PosterBoardInstallResult?
    @State private var showsHashSettings = false
    @State private var showsRespring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    AnimatedImage(url: wallpaper.previewURL, contentMode: .fit)
                        .frame(height: 320)
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
                            installDirectly()
                        } label: {
                            if installer.isInstalling {
                                HStack {
                                    ProgressView().tint(.white)
                                    Text(installer.progressMessage ?? "Installation…")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Label("Installer dans Island", systemImage: "square.and.arrow.down.badge.checkmark")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(installer.isInstalling)

                        if let installResult {
                            VStack(spacing: 4) {
                                Label(
                                    "\(installResult.copiedItemNames.count) fichier(s) copié(s). SpringBoard va redémarrer.",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .font(.caption)
                                .foregroundStyle(.green)
                                .multilineTextAlignment(.center)

                                ForEach(installResult.copiedItemNames, id: \.self) { name in
                                    Text(name)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                ForEach(installResult.destinationPaths, id: \.self) { path in
                                    Text(path)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.white.opacity(0.4))
                                        .lineLimit(2)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                        if let installError {
                            Text(installError)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            showsHashSettings = true
                        } label: {
                            Label("Réglages du hash PosterBoard", systemImage: "gearshape")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)

                        Divider()
                            .overlay(Color.white.opacity(0.15))
                            .padding(.vertical, 4)

                        Button {
                            openInPocketPoster()
                        } label: {
                            Label("Ouvrir dans Pocket Poster", systemImage: "square.and.arrow.down.on.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)

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
            .overlay {
                if showsRespring {
                    NeoSpringView()
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showsHashSettings) {
            PosterBoardHashSettingsView()
        }
    }

    private func installDirectly() {
        installError = nil
        installResult = nil
        Task {
            do {
                let result = try await installer.install(wallpaper: wallpaper)
                installResult = result
                try? await Task.sleep(for: .seconds(1))
                showsRespring = true
            } catch {
                installError = error.localizedDescription
            }
        }
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
