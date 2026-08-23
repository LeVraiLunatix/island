import SwiftUI

private enum MenuDestination: Hashable {
    case dynamicIsland
    case appleIntelligence
    case deviceName
    case category(GestaltTweakCategory)
    case wallpapers
}

private struct MenuCard: Identifiable {
    let title: String
    let subtitle: String
    let systemImage: String
    let destination: MenuDestination
    var requiresConnection = true

    var id: String { title }
}

struct MenuView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    private let cards: [MenuCard] = [
        MenuCard(title: "Dynamic Island", subtitle: "Choisir un modèle", systemImage: "capsule.fill", destination: .dynamicIsland),
        MenuCard(title: "Apple Intelligence", subtitle: "Forcer la région US", systemImage: "sparkles", destination: .appleIntelligence),
        MenuCard(title: "Nom de l'appareil", subtitle: "Modifier le modèle affiché", systemImage: "textformat", destination: .deviceName),
        MenuCard(title: "Fonds d'écran", subtitle: "Bibliothèque Cowabunga", systemImage: "photo.stack.fill", destination: .wallpapers, requiresConnection: false),
        MenuCard(title: "Affichage", subtitle: "AOD, parallaxe, Liquid Glass", systemImage: "sun.max.fill", destination: .category(.display)),
        MenuCard(title: "Matériel", subtitle: "Camera Control, Pencil…", systemImage: "cpu", destination: .category(.hardware)),
        MenuCard(title: "iPad", subtitle: "Stage Manager, apps iPad", systemImage: "ipad", destination: .category(.ipad)),
        MenuCard(title: "Interne & Recherche", subtitle: "Fonctions avancées", systemImage: "wrench.and.screwdriver.fill", destination: .category(.internalFeatures))
    ]

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statusPill

                    GlassEffectContainer(spacing: 16) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(cards) { card in
                                NavigationLink(value: card.destination) {
                                    MenuCardView(card: card)
                                }
                                .buttonStyle(.plain)
                                .disabled(card.requiresConnection && viewModel.plist == nil)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, viewModel.hasStagedTweaks ? 90 : 20)
            }
            .background(Color.black)
            .navigationTitle("Island")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { viewModel.load() }
            .navigationDestination(for: MenuDestination.self) { destination in
                switch destination {
                case .dynamicIsland:
                    DynamicIslandDetailView()
                case .appleIntelligence:
                    AppleIntelligenceDetailView()
                case .deviceName:
                    DeviceNameDetailView()
                case .category(let category):
                    CategoryDetailView(category: category)
                case .wallpapers:
                    WallpapersView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasStagedTweaks {
                    applyBar
                }
            }
        }
        .tint(.white)
    }

    @ViewBuilder
    private var statusPill: some View {
        HStack(spacing: 8) {
            if viewModel.plist != nil {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text(viewModel.aiRegionProfile?.marketingName ?? "Connecté")
                    .foregroundStyle(.white)
            } else if viewModel.isBusy || !viewModel.hasAttemptedLoad {
                ProgressView()
                    .tint(.white)
                Text("Connexion…")
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("Erreur de connexion")
                    .foregroundStyle(.red)
                Button("Réessayer", action: viewModel.load)
                    .font(.caption.weight(.semibold))
            }
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
    }

    private var applyBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.stagedChangeCount) modification(s) en attente")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Sauvegarde automatique · redémarre SpringBoard")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Button {
                viewModel.applySelectedTweaks()
            } label: {
                Text("Appliquer")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.glassProminent)
            .disabled(viewModel.isBusy)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

private struct MenuCardView: View {
    let card: MenuCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: card.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
            Spacer(minLength: 8)
            Text(card.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(card.subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct DynamicIslandDetailView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Modèle", selection: $viewModel.dynamicIslandSubtype) {
                    Text("Aucun changement").tag(Int?.none)
                    ForEach(DynamicIslandOption.all) { option in
                        Text(option.title).tag(Int?.some(option.subtype))
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
                .tint(.white)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Text("La sélection écrit ArtworkDeviceSubType et l'indicateur de compatibilité Dynamic Island.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .background(Color.black)
        .navigationTitle("Dynamic Island")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppleIntelligenceDetailView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { viewModel.stagesAIRegion },
                    set: { viewModel.setAIRegion(enabled: $0) }
                )) {
                    Text("Activer Apple Intelligence (région US)")
                        .foregroundStyle(.white)
                }
                .tint(.white)

                if viewModel.requiresForcedAIEnable {
                    Label(
                        "Appareil non éligible : activation forcée avec usurpation d'identité de l'appareil. Face ID ou la stabilité du système peuvent être affectées.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(20)
        }
        .background(Color.black)
        .navigationTitle("Apple Intelligence")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DeviceNameDetailView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Changer le nom du modèle dans Réglages", isOn: $viewModel.changesModelName)
                    .foregroundStyle(.white)
                    .tint(.white)

                if viewModel.changesModelName {
                    TextField("Nom du modèle", text: $viewModel.modelName)
                        .textInputAutocapitalization(.words)
                        .padding(12)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(20)
        }
        .background(Color.black)
        .navigationTitle("Nom de l'appareil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CategoryDetailView: View {
    let category: GestaltTweakCategory
    @EnvironmentObject private var viewModel: GestaltViewModel

    private var definitions: [GestaltTweakDefinition] {
        GestaltTweakCatalog.definitions.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(definitions) { definition in
                        TweakGlassRow(
                            definition: definition,
                            isOn: Binding(
                                get: { viewModel.selectedTweaks.contains(definition.id) },
                                set: { viewModel.setTweak(definition.id, enabled: $0) }
                            )
                        )
                    }
                }
                .padding(20)
            }
        }
        .background(Color.black)
        .navigationTitle(category.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TweakGlassRow: View {
    let definition: GestaltTweakDefinition
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(definition.title)
                        .foregroundStyle(.white)
                    if definition.isRisky {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Text(definition.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(.white)
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    MenuView()
        .environmentObject(GestaltViewModel())
}
