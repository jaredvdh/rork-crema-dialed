//
//  MaintenanceLog.swift
//  CremaDialed
//

import Foundation
import SwiftData

@Model
final class MaintenanceLog {
    var id: UUID
    var kindRaw: String
    var machine: Machine?
    var date: Date
    var notes: String

    init(kind: MaintenanceKind, machine: Machine? = nil, date: Date = Date(), notes: String = "") {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.machine = machine
        self.date = date
        self.notes = notes
    }

    var kind: MaintenanceKind { MaintenanceKind(rawValue: kindRaw) ?? .backflush }

    var nextDue: Date {
        Calendar.current.date(byAdding: .day, value: kind.intervalDays, to: date) ?? date
    }

    var isOverdue: Bool { nextDue < Date() }
}
