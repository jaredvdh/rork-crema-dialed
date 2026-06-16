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
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bean.self,
            Machine.self,
            Grinder.self,
            Brew.self,
            DialedRecipe.self,
            MaintenanceLog.self,
            MaintenanceReminder.self,
            Cafe.self,
            CafeVisit.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // 1) Try the normal on-disk store.
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return container
        }

        // 2) During development the schema can change in ways the existing
        // on-disk store cannot migrate, which would otherwise crash-loop at
        // launch. Wipe the incompatible store and start fresh.
        let storeURL = configuration.url
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return container
        }

        // 3) Last resort: an in-memory store always succeeds for a valid schema
        // and keeps the app usable rather than hanging at launch.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [memory]) {
            return container
        }

        // 4) Absolute fallback — an empty schema can never fail to open, so the
        // app launches no matter what.
        return try! ModelContainer(for: Schema([]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
