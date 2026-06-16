//
//  CremaDataStore.swift
//  CremaDialed
//
//  Owns the SwiftData schema, its versioned migration path, and the logic that
//  safely opens the on-disk store. The migration plan establishes a formal
//  upgrade path so future model changes can migrate user data instead of
//  silently destroying it.
//
//  IMPORTANT: How to evolve the schema safely.
//
//  - ADDITIVE / LIGHTWEIGHT changes (adding an optional property, adding a new
//    @Model, removing a property, renaming with @Attribute(originalName:)) need
//    NO new versioned schema and NO migration plan. SwiftData performs these
//    automatically when the container opens. Simply update the model and bump
//    `CremaSchema.versionIdentifier`.
//    (`CafeVisit.beanID` was added exactly this way — as an optional — so it
//    migrates automatically with no data loss.)
//
//  - NON-LIGHTWEIGHT changes (a new NON-optional property without a default,
//    a type change, splitting/merging models, or any change that requires
//    transforming existing data) MUST introduce a SECOND versioned schema that
//    captures the OLD shape using DISTINCT model type definitions, plus a
//    `SchemaMigrationPlan` with a `.custom` stage. CRITICAL: two versioned
//    schemas that reference the SAME live @Model classes resolve to the same
//    checksum and crash on launch with "Duplicate version checksums across
//    stages detected" — so only add a V2 when the model shapes genuinely differ.
//
//  The destructive "wipe and start fresh" path below only exists as an absolute
//  last resort for a store that is genuinely corrupt or unreadable.
//

import Foundation
import SwiftData

/// The current persisted model set. SwiftData migrates existing on-disk stores
/// to this shape automatically for lightweight changes. Bump
/// `versionIdentifier` whenever the model set changes so the version is
/// recorded; introduce a separate versioned schema + migration plan only for
/// non-lightweight changes (see the file header).
enum CremaSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Bean.self,
            Machine.self,
            Grinder.self,
            Brew.self,
            DialedRecipe.self,
            MaintenanceLog.self,
            MaintenanceReminder.self,
            Cafe.self,
            CafeVisit.self,
        ]
    }
}

enum CremaDataStore {
    /// Set to `true` when the on-disk store could not be opened or migrated and
    /// had to be reset. `RootView` reads this once to inform the user and then
    /// clears it.
    static let didResetStoreKey = "cremaDidResetLocalStore"

    /// The current schema, derived from the versioned schema.
    static var currentSchema: Schema { Schema(versionedSchema: CremaSchema.self) }

    /// Build the shared container. Tries the on-disk store first (SwiftData
    /// applies automatic lightweight migration for compatible changes) and only
    /// falls back to destructive recovery when the store genuinely cannot be
    /// opened — recording that fact so the UI can warn the user.
    static func makeContainer() -> ModelContainer {
        let schema = currentSchema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // 1) Normal path: open the on-disk store. SwiftData automatically
        // performs lightweight migration (e.g. the added optional `beanID`)
        // without losing data. A migration plan is only needed for
        // non-lightweight changes (see the file header).
        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // Opening/migrating failed. This should be rare in production and
            // always indicates the local store is unusable.
            #if DEBUG
            print("[CremaDataStore] Failed to open store: \(error.localizedDescription)")
            #endif
        }

        // 2) Last-resort recovery: the store is corrupt or has an incompatible
        // shape with no migration path. Reset it so the app remains usable, but
        // flag the data loss so the user is told rather than failing silently.
        let storeURL = configuration.url
        let fileManager = FileManager.default
        var didDeleteExistingStore = false
        for suffix in ["", "-wal", "-shm"] {
            let url = URL(fileURLWithPath: storeURL.path + suffix)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
                didDeleteExistingStore = true
            }
        }
        if didDeleteExistingStore {
            UserDefaults.standard.set(true, forKey: didResetStoreKey)
        }
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            return container
        }

        // 3) Disk-backed recovery itself failed — fall back to an in-memory
        // store so the app still launches (data will not persist this session).
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [memory]) {
            UserDefaults.standard.set(true, forKey: didResetStoreKey)
            return container
        }

        // 4) Absolute fallback — an empty schema can never fail to open.
        return try! ModelContainer(
            for: Schema([]),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }
}
