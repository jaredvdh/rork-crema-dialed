//
//  MaintenanceEngine.swift
//  CremaDialed
//
//  Computes maintenance reminder status from logged history and either elapsed
//  time or the number of coffees pulled since a task was last completed.
//

import Foundation

struct MaintenanceStatus {
    let kind: MaintenanceKind
    let mode: MaintenanceFrequencyMode
    let lastDone: Date?
    /// 0 = just done, 1 = exactly due, >1 = overdue.
    let progress: Double
    let isDue: Bool
    let summary: String
}

enum MaintenanceEngine {
    /// The maintenance tasks that apply to a machine, optionally including
    /// grinder-specific tasks when a grinder is attached or integrated.
    static func applicableKinds(hasGrinder: Bool) -> [MaintenanceKind] {
        MaintenanceKind.allCases.filter { hasGrinder || !$0.isGrinderTask }
    }

    /// Compute the status of a single task.
    /// - Parameters:
    ///   - lastDone: date the task was last completed (nil if never).
    ///   - shotsSince: coffees pulled on this machine since `lastDone`.
    static func status(
        kind: MaintenanceKind,
        mode: MaintenanceFrequencyMode,
        intervalDays: Int,
        intervalShots: Int,
        lastDone: Date?,
        shotsSince: Int
    ) -> MaintenanceStatus {
        switch mode {
        case .off:
            return MaintenanceStatus(kind: kind, mode: .off, lastDone: lastDone,
                                     progress: 0, isDue: false,
                                     summary: lastDone == nil ? "Not tracked" : "Last done \(Self.relative(lastDone!))")
        case .shots:
            let interval = max(1, intervalShots)
            let progress = Double(shotsSince) / Double(interval)
            let remaining = interval - shotsSince
            let summary: String
            if remaining <= 0 {
                summary = "Due now · \(shotsSince) coffees pulled"
            } else {
                summary = "\(remaining) coffee\(remaining == 1 ? "" : "s") to go"
            }
            return MaintenanceStatus(kind: kind, mode: .shots, lastDone: lastDone,
                                     progress: progress, isDue: remaining <= 0, summary: summary)
        case .time:
            let interval = max(1, intervalDays)
            guard let lastDone else {
                return MaintenanceStatus(kind: kind, mode: .time, lastDone: nil,
                                         progress: 1, isDue: true, summary: "Never logged")
            }
            let due = Calendar.current.date(byAdding: .day, value: interval, to: lastDone) ?? lastDone
            let total = due.timeIntervalSince(lastDone)
            let elapsed = Date().timeIntervalSince(lastDone)
            let progress = total > 0 ? elapsed / total : 1
            let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
            let summary: String
            if days < 0 {
                summary = "Overdue by \(-days) day\(-days == 1 ? "" : "s")"
            } else if days == 0 {
                summary = "Due today"
            } else {
                summary = "Due in \(days) day\(days == 1 ? "" : "s")"
            }
            return MaintenanceStatus(kind: kind, mode: .time, lastDone: lastDone,
                                     progress: progress, isDue: days <= 0, summary: summary)
        }
    }

    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
