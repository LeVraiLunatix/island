import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: GestaltViewModel
    @State private var showsLaunchAnimation = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if GestaltAccess.isRunningSupportedOS() {
                MenuView()
                    .task { viewModel.load() }
            } else {
                UnsupportedOSView()
            }

            if showsLaunchAnimation {
                LaunchAnimationView {
                    showsLaunchAnimation = false
                }
                .zIndex(1)
            }

            if viewModel.isRespringing {
                NeoSpringView()
                    .zIndex(2)
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
            Text("Version d'iOS non prise en charge")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Island ne fonctionne que sur iOS/iPadOS 27 bêta 1 à bêta 4.")
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
