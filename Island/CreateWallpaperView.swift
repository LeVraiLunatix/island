import PhotosUI
import SwiftUI
import UIKit

struct CreateWallpaperView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var installer = PosterBoardInstaller()

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var wallpaperName = "Mon fond d'écran"

    @State private var isBuilding = false
    @State private var buildError: String?
    @State private var installResult: PosterBoardInstallResult?
    @State private var installError: String?
    @State private var exportedTendiesURL: URL?

    @State private var showsHashSettings = false
    @State private var showsRespring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        previewArea
                    }
                    .buttonStyle(.plain)

                    if pickedImage != nil {
                        formArea
                    }

                    if let buildError {
                        Text(buildError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationTitle("Créer un fond d'écran")
            .navigationBarTitleDisplayMode(.inline)
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
        .task(id: photosPickerItem) {
            await loadPickedImage()
        }
    }

    @ViewBuilder
    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.06))
            if let pickedImage {
                Image(uiImage: pickedImage)
                    .resizable()
                    .aspectRatio(
                        CustomWallpaperTemplate.canvasSize.width / CustomWallpaperTemplate.canvasSize.height,
                        contentMode: .fill
                    )
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Choisir une photo")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(height: 320)
        .padding(.horizontal, 20)
        .clipped()
    }

    @ViewBuilder
    private var formArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Nom", text: $wallpaperName)
                .padding(12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text("La photo est recadrée en plein écran (390×844 pt) et posée telle quelle, sans les couches animées des fonds d'écran de la bibliothèque Cowabunga.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))

            Button {
                installDirectly()
            } label: {
                if isBuilding || installer.isInstalling {
                    HStack {
                        ProgressView().tint(.white)
                        Text(installer.progressMessage ?? "Préparation…")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Installer dans Island", systemImage: "square.and.arrow.down.badge.checkmark")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.glassProminent)
            .disabled(isBuilding || installer.isInstalling)

            if let installResult {
                Label(
                    "\(installResult.copiedItemNames.count) fichier(s) copié(s). SpringBoard va redémarrer.",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.green)
            }
            if let installError {
                Text(installError)
                    .font(.caption)
                    .foregroundStyle(.orange)
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
                exportTendies()
            } label: {
                Label("Générer le fichier .tendies", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .disabled(isBuilding)

            if let exportedTendiesURL {
                ShareLink(item: exportedTendiesURL) {
                    Label("Partager \(exportedTendiesURL.lastPathComponent)", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(.horizontal, 24)
    }

    private func loadPickedImage() async {
        guard let photosPickerItem else { return }
        buildError = nil
        installResult = nil
        installError = nil
        exportedTendiesURL = nil
        do {
            guard let data = try await photosPickerItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                buildError = "Impossible de charger cette photo."
                return
            }
            pickedImage = image
        } catch {
            buildError = error.localizedDescription
        }
    }

    private func installDirectly() {
        guard let pickedImage else { return }
        buildError = nil
        installError = nil
        installResult = nil
        isBuilding = true
        Task {
            do {
                let descriptorsFolder = try CustomWallpaperBuilder.buildDescriptorsFolder(from: pickedImage)
                defer { try? FileManager.default.removeItem(at: descriptorsFolder.deletingLastPathComponent()) }
                isBuilding = false
                let result = try await installer.installCustomDescriptors(at: descriptorsFolder)
                installResult = result
                try? await Task.sleep(for: .seconds(1))
                showsRespring = true
            } catch {
                isBuilding = false
                installError = error.localizedDescription
            }
        }
    }

    private func exportTendies() {
        guard let pickedImage else { return }
        buildError = nil
        isBuilding = true
        Task {
            do {
                let descriptorsFolder = try CustomWallpaperBuilder.buildDescriptorsFolder(from: pickedImage)
                let tendiesURL = try CustomWallpaperBuilder.exportTendies(descriptorsFolder: descriptorsFolder, name: wallpaperName)
                try? FileManager.default.removeItem(at: descriptorsFolder.deletingLastPathComponent())
                exportedTendiesURL = tendiesURL
            } catch {
                buildError = error.localizedDescription
            }
            isBuilding = false
        }
    }
}

#Preview {
    CreateWallpaperView()
}
