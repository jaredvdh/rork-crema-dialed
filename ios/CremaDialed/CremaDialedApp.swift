//
//  CremaDialedApp.swift
//  CremaDialed
//
//  Created by Rork on June 9, 2026.
//

import SwiftUI
import SwiftData

@main
struct CremaDialedApp: App {
    // The store is created through CremaDataStore, which applies the versioned
    // schema + migration plan and only resets local data as a last resort
    // (surfacing a one-time alert in RootView when it has to).
    let sharedModelContainer: ModelContainer = CremaDataStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
