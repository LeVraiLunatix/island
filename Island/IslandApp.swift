import SwiftUI
import UIKit

@main
struct IslandApp: App {
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .onOpenURL { url in handleCallback(url) }
                .task { state.evaluateBackend() }
        }
    }

    private func handleCallback(_ url: URL) {
        guard url.scheme == "island" else { return }
        switch url.host {
        case "applied":    state.lastResult = .applied
        case "respringed": state.lastResult = .respringed
        case "reverted":   state.lastResult = .reverted
        default:           break
        }
    }
}

final class AppState: ObservableObject {
    static let shared = AppState()

    enum Result { case idle, applied, respringed, reverted, failed(String) }

    @Published var backend: ExploitBackend = .unsupported
    @Published var backendLabel: String = ""
    @Published var pocketPosterInstalled: Bool = false
    @Published var lastResult: Result = .idle

    func evaluateBackend() {
        self.backend = VersionRouter.pick()
        self.backendLabel = VersionRouter.humanBackendLabel()
        self.pocketPosterInstalled =
            UIApplication.shared.canOpenURL(URL(string: "pocketposter://")!)
    }
}
