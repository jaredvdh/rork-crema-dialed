//
//  MaintenanceReminder.swift
//  CremaDialed
//
//  A per-machine reminder configuration for a maintenance task. Reminders can
//  be scheduled by elapsed time or by the number of coffees pulled since the
//  task was last completed.
//

import Foundation
import SwiftData

@Model
final class MaintenanceReminder {
    var id: UUID
    var machine: Machine?
    var kindRaw: String
    var modeRaw: String
    var intervalDays: Int
    var intervalShots: Int
    var createdAt: Date

    init(
        machine: Machine?,
        kind: MaintenanceKind,
        mode: MaintenanceFrequencyMode? = nil,
        intervalDays: Int? = nil,
        intervalShots: Int? = nil
    ) {
        self.id = UUID()
        self.machine = machine
        self.kindRaw = kind.rawValue
        self.modeRaw = (mode ?? kind.defaultMode).rawValue
        self.intervalDays = intervalDays ?? kind.intervalDays
        self.intervalShots = intervalShots ?? kind.intervalShots
        self.createdAt = Date()
    }

    var kind: MaintenanceKind { MaintenanceKind(rawValue: kindRaw) ?? .clean }
    var mode: MaintenanceFrequencyMode {
        get { MaintenanceFrequencyMode(rawValue: modeRaw) ?? .off }
        set { modeRaw = newValue.rawValue }
    }
}
