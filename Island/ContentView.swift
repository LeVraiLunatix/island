import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if GestaltAccess.isRunningSupportedOS() {
                mainContent
            } else {
                UnsupportedOSView()
            }

            if viewModel.isRespringing {
                NeoSpringView()
            }
        }
        .preferredColorScheme(.dark)
        .task { viewModel.load() }
        .alert(item: $viewModel.notice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var mainContent: some View {
        VStack(spacing: 28) {
            Text("Island")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 48)

            statusView

            Spacer()

            VStack(spacing: 6) {
                Text("SUBTYPE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.4))
                    .kerning(1.2)

                Picker("Subtype", selection: $viewModel.dynamicIslandSubtype) {
                    ForEach(DynamicIslandOption.all) { option in
                        Text(option.title)
                            .tag(option.subtype)
                    }
                }
                .pickerStyle(.wheel)
                .colorScheme(.dark)
                .frame(height: 150)
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 24)

            Button {
                viewModel.applySelectedTweaks()
            } label: {
                Text("Activer")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.black)
            .disabled(viewModel.plist == nil || viewModel.isBusy)
            .padding(.horizontal, 24)

            Spacer()

            Text("Redémarre SpringBoard automatiquement")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        HStack(spacing: 8) {
            if viewModel.plist != nil {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Connecté")
                    .foregroundStyle(.green)
            } else if viewModel.isBusy || !viewModel.hasAttemptedLoad {
                ProgressView()
                    .tint(.white)
                Text("Connexion…")
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("Erreur de connexion")
                    .foregroundStyle(.red)
            }
        }
        .font(.subheadline.weight(.medium))
    }
}

private struct UnsupportedOSView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.5))
            Text("OS Non Supporté")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Island fonctionne uniquement sur iOS/iPadOS 27 beta 1 à beta 4.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(24)
    }
}

#Preview {
    ContentView()
        .environmentObject(GestaltViewModel())
}
