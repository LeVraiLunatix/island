import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if GestaltAccess.isRunningSupportedOS() {
                TweakWorkbench()
                    .task { viewModel.load() }
            } else {
                UnsupportedOSView()
            }

            if viewModel.isRespringing {
                NeoSpringView()
            }
        }
        .preferredColorScheme(.dark)
        .alert(item: $viewModel.notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

private struct UnsupportedOSView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.5))
            Text("Unsupported OS Version")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Island currently supports only iOS and iPadOS 27 beta 1 through beta 4.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(24)
    }
}

private struct TweakWorkbench: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        NavigationStack {
            List {
                Section { deviceStatus }
                    .listRowBackground(Color.white.opacity(0.06))

                if viewModel.plist != nil {
                    dynamicIslandSection
                    aiRegionSection
                    modelNameSection

                    ForEach(GestaltTweakCategory.allCases) { category in
                        tweakSection(category)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Island")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { viewModel.load() }
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasStagedTweaks {
                    applyBar
                }
            }
        }
        .tint(.white)
    }

    private func tweakSection(_ category: GestaltTweakCategory) -> some View {
        let definitions = GestaltTweakCatalog.definitions.filter { $0.category == category }
        return Section(category.label) {
            ForEach(definitions) { definition in
                TweakToggle(
                    definition: definition,
                    isOn: Binding(
                        get: { viewModel.selectedTweaks.contains(definition.id) },
                        set: { viewModel.setTweak(definition.id, enabled: $0) }
                    )
                )
            }
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    @ViewBuilder
    private var deviceStatus: some View {
        if viewModel.plist == nil {
            HStack(spacing: 10) {
                if viewModel.isBusy || !viewModel.hasAttemptedLoad {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                    Text("Reading MobileGestalt…")
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unable to read MobileGestalt")
                            .foregroundStyle(.white)
                        Button("Reload", action: viewModel.load)
                            .font(.footnote)
                    }
                }
            }
        } else {
            LabeledContent {
                Text("Connected")
                    .foregroundStyle(.green)
            } label: {
                Label(viewModel.aiRegionProfile?.marketingName ?? String(localized: "Current Device"), systemImage: "iphone")
                    .foregroundStyle(.white)
            }
        }
    }

    private var dynamicIslandSection: some View {
        Section {
            Picker("Subtype", selection: $viewModel.dynamicIslandSubtype) {
                Text("No Change").tag(Int?.none)
                ForEach(DynamicIslandOption.all) { option in
                    Text(option.title).tag(Int?.some(option.subtype))
                }
            }
            .tint(.white)
        } header: {
            Text("Dynamic Island")
        } footer: {
            Text("Selecting a subtype writes ArtworkDeviceSubType and the Dynamic Island support flag.")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var aiRegionSection: some View {
        Section {
            Toggle(
                isOn: Binding(
                    get: { viewModel.stagesAIRegion },
                    set: { viewModel.setAIRegion(enabled: $0) }
                )
            ) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Enable Apple Intelligence (US Region)")
                        if viewModel.requiresForcedAIEnable {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityLabel("High Risk")
                        }
                    }
                    if viewModel.requiresForcedAIEnable {
                        Text("Unsupported device: force enable with device identity spoofing. Face ID or system stability may be affected.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } header: {
            Text("Apple Intelligence")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var modelNameSection: some View {
        Section("Device Name") {
            Toggle("Change model name in About", isOn: $viewModel.changesModelName)
            if viewModel.changesModelName {
                TextField("Model Name", text: $viewModel.modelName)
                    .textInputAutocapitalization(.words)
            }
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var applyBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: String(localized: "%d pending changes"), viewModel.stagedChangeCount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Automatic backup · restarts SpringBoard")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Button("Activer") { viewModel.applySelectedTweaks() }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(viewModel.isBusy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.95))
    }
}

private struct TweakToggle: View {
    let definition: GestaltTweakDefinition
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(definition.title)
                    if definition.isRisky {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("High Risk")
                    }
                }
                Text(definition.detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GestaltViewModel())
}
