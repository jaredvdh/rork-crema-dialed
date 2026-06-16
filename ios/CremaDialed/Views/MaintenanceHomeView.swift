//
//  MaintenanceHomeView.swift
//  CremaDialed
//
//  The maintenance entry point inside Settings: a per-machine overview that
//  links into each machine's existing maintenance hub (backflush, descale,
//  group head, water filter, grinder care and reminders).
//

import SwiftUI
import SwiftData

struct MaintenanceHomeView: View {
    @Query(sort: \Machine.createdAt, order: .reverse) private var machines: [Machine]
    @Query(sort: \Grinder.createdAt, order: .reverse) private var grinders: [Grinder]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if machines.isEmpty {
                    emptyState
                } else {
                    intro
                    ForEach(machines) { machine in
                        NavigationLink(value: MachineRoute(id: machine.id)) {
                            machineCard(machine)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hasGrinder: Bool { !grinders.isEmpty }

    private var intro: some View {
        Text("Track servicing and cleaning for each machine — backflush, descale, group head, water filter and grinder care, with optional reminders.")
            .font(.crema(13, .medium))
            .foregroundStyle(CremaColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func machineCard(_ machine: Machine) -> some View {
        CremaCard {
            HStack(spacing: 14) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.crema(18))
                    .foregroundStyle(CremaColor.caramel)
                    .frame(width: 44, height: 44)
                    .background(CremaColor.surface)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(machine.displayName)
                        .font(.crema(16, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                    Text(subtitle(for: machine))
                        .font(.crema(13, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.crema(13, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
            }
        }
    }

    private func subtitle(for machine: Machine) -> String {
        let logs = machine.maintenanceLogs
        guard let last = logs.max(by: { $0.date < $1.date }) else {
            return "No maintenance logged yet"
        }
        return "Last: \(last.kind.rawValue) · \(last.date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var emptyState: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("No machines yet", systemImage: "wrench.and.screwdriver")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text("Add an espresso machine under Equipment to start tracking maintenance and reminders.")
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
    }
}

/// Resolves a `MachineRoute` to the machine's maintenance hub, shared by the
/// Equipment and Maintenance sections of Settings.
struct MaintenanceDestination: View {
    let machineID: UUID

    @Query private var machines: [Machine]
    @Query private var grinders: [Grinder]

    var body: some View {
        if let machine = machines.first(where: { $0.id == machineID }) {
            MaintenanceView(machine: machine, hasGrinder: hasGrinder(for: machine))
        } else {
            ContentUnavailableView("Machine not found", systemImage: "wrench.and.screwdriver")
        }
    }

    private func hasGrinder(for machine: Machine) -> Bool {
        machine.hasIntegratedGrinder || !grinders.isEmpty
    }
}
