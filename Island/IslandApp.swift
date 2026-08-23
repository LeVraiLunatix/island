//
//  IslandApp.swift
//  Island
//

import SwiftUI

@main
struct IslandApp: App {
    @StateObject private var viewModel = GestaltViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
