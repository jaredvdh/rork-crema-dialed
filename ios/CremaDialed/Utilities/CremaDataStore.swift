//
//  CremaDataStore.swift
//  CremaDialed
//
//  Owns the SwiftData schema, its versioned migration path, and the logic that
//  safely opens the on-disk store. The migration plan establishes a formal
//  upgrade path so future model changes can migrate user data instead of
//  silently destroying it.
//
//  IMPORTANT: Every future @Model change (adding/removing/renaming a model or a
//  property in a way SwiftData cannot infer automatically) MUST be paired with:
//    1. A new versioned schema (e.g. `CremaSchemaV2`) capturing the new shape.
//    2. A new `MigrationStage` in `CremaMigrationPlan.stages` describing how to
//       move data from the previous version to the new one.
//  Skipping this re-introduces the silent "wipe and start fresh" data loss the
//  recovery path below only exists to guard against as an absolute last resort.
//

import Foundation
import SwiftData

/// Version 1 of the persisted model set. This is the baseline shape shipped to
/// users; new versions are added alongside it (never edited in place once
/// shipped) so migrations have a stable starting point.
enum CremaSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

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

/// Version 2 adds an optional `beanID` to `CafeVisit`, linking a café check-in
/// to one of the user's saved beans. Adding a new optional property is a
/// lightweight migration SwiftData can perform automatically.
enum CremaSchemaV2: VersionedSchema {
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

/// The ordered list of schema versions and the migration stages that connect
/// them. Each version bump is paired with a stage so user data is migrated
/// rather than destroyed.
enum CremaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CremaSchemaV1.self, CremaSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        // Add a `.lightweight` or `.custom` stage here for each future version
        // bump — e.g. `migrateV2toV3`. Never leave a version bump without a stage.
        [migrateV1toV2]
    }

    /// V1 → V2: adding the optional `CafeVisit.beanID` requires no data
    /// transformation, so a lightweight stage suffices.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: CremaSchemaV1.self,
        toVersion: CremaSchemaV2.self
    )
}

enum CremaDataStore {
    /// Set to `true` when the on-disk store could not be opened or migrated and
    /// had to be reset. `RootView` reads this once to inform the user and then
    /// clears it.
    static let didResetStoreKey = "cremaDidResetLocalStore"

    /// The current schema, derived from the latest versioned schema.
    static var currentSchema: Schema { Schema(versionedSchema: CremaSchemaV2.self) }

    /// Build the shared container. Tries the migrating on-disk store first and
    /// only falls back to destructive recovery when the store genuinely cannot
    /// be opened — recording that fact so the UI can warn the user.
    static func makeContainer() -> ModelContainer {
        let schema = currentSchema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // 1) Normal path: open the on-disk store, applying the migration plan.
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: CremaMigrationPlan.self,
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
