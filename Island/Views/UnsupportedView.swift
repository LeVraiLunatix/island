import SwiftUI
import UIKit

struct BackendBanner: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            if state.backend == .nuggetBackup && !state.pocketPosterInstalled {
                promptInstall
            } else if state.backend == .unsupported {
                unsupported
            } else {
                supported
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.04)))
    }

    private var promptInstall: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pocket Poster requis")
                .font(.headline).foregroundStyle(.white)
            Text("Sur iOS 27.0.1+, Island écrit via Pocket Poster " +
                 "(technique Mobile Backup). Installe-le une fois, " +
                 "puis reviens ici.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.7))
            Button {
                if let u = URL(string: "https://cowabun.ga") {
                    UIApplication.shared.open(u)
                }
            } label: {
                Text("Ouvrir cowabun.ga")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.43, green: 0.34, blue: 0.81)))
                    .foregroundStyle(.white)
            }
        }
    }

    private var unsupported: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("iOS \(UIDevice.current.systemVersion) non supporté")
                .font(.headline).foregroundStyle(.white)
            Text("Island cible iOS 27. Build actuel : " +
                 VersionRouter.currentBuild())
                .font(.footnote).foregroundStyle(.white.opacity(0.6))
        }
    }

    private var supported: some View {
        HStack {
            Circle().fill(.green).frame(width: 8, height: 8)
            Text("Backend prêt : \(state.backendLabel)")
                .font(.footnote).foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }
}
