//
//  EquipmentView.swift
//  CremaDialed
//

import SwiftUI
import SwiftData

struct EquipmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Machine.createdAt, order: .reverse) private var machines: [Machine]
    @Query(sort: \Grinder.createdAt, order: .reverse) private var grinders: [Grinder]
    @Query(sort: \MaintenanceLog.date, order: .reverse) private var logs: [MaintenanceLog]

    @State private var showAddMachine = false
    @State private var showAddGrinder = false
    @State private var showLogMaintenance = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                machinesSection
                grindersSection
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddMachine) {
            AddMachineSheet { machine in
                modelContext.insert(machine)
                if machine.hasIntegratedGrinder {
                    modelContext.insert(Grinder(manufacturer: machine.manufacturer,
                                                model: "\(machine.model) Grinder",
                                                kind: .stepped, isIntegrated: true))
                }
                HapticEngine.success()
            }
        }
        .sheet(isPresented: $showAddGrinder) {
            AddGrinderSheet { grinder in
                modelContext.insert(grinder)
                HapticEngine.success()
            }
        }
        .sheet(isPresented: $showLogMaintenance) {
            LogMaintenanceSheet(machines: machines) { log in
                modelContext.insert(log)
                HapticEngine.success()
            }
        }
    }

    private func hasGrinder(for machine: Machine) -> Bool {
        machine.hasIntegratedGrinder || !grinders.isEmpty
    }

    private var machinesSection: some View {
        VStack(spacing: 10) {
            SectionHeader("Machines") {
                addButton { showAddMachine = true }
            }
            if machines.isEmpty {
                emptyHint("Add your espresso machine to tailor the dial-in tools.")
            } else {
                ForEach(machines) { machine in
                    SwipeToDelete(
                        onDelete: { deleteMachine(machine) },
                        confirmTitle: "Delete Machine?",
                        confirmMessage: "This removes the machine and its maintenance logs. Past journal entries that used it are kept."
                    ) {
                        NavigationLink(value: MachineRoute(id: machine.id)) {
                            CremaCard {
                                HStack(spacing: 14) {
                                    iconBadge("cup.and.saucer.fill")
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(machine.displayName)
                                            .font(.crema(16, .bold))
                                            .foregroundStyle(CremaColor.textPrimary)
                                        Text("\(machine.boilerType.rawValue) · \(machine.pumpType.rawValue)")
                                            .font(.crema(13, .medium))
                                            .foregroundStyle(CremaColor.textSecondary)
                                        Label("Maintenance & care", systemImage: "wrench.and.screwdriver.fill")
                                            .font(.crema(12, .semibold))
                                            .foregroundStyle(CremaColor.caramel)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.crema(13, .semibold))
                                        .foregroundStyle(CremaColor.textTertiary)
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }

    private var grindersSection: some View {
        VStack(spacing: 10) {
            SectionHeader("Grinders") {
                addButton { showAddGrinder = true }
            }
            if grinders.isEmpty {
                emptyHint("Add a grinder so the coach can give precise grind advice.")
            } else {
                ForEach(grinders) { grinder in
                    SwipeToDelete(
                        onDelete: { deleteGrinder(grinder) },
                        confirmTitle: "Delete Grinder?",
                        confirmMessage: "This removes the grinder. Past journal entries that used it are kept."
                    ) {
                        CremaCard {
                            HStack(spacing: 14) {
                                iconBadge("dial.high.fill")
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(grinder.displayName)
                                        .font(.crema(16, .bold))
                                        .foregroundStyle(CremaColor.textPrimary)
                                    Text("\(grinder.kind.rawValue) · \(grinder.burrType.rawValue) \(grinder.burrSizeMM)mm")
                                        .font(.crema(13, .medium))
                                        .foregroundStyle(CremaColor.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
        }
    }

    private var maintenanceSection: some View {
        VStack(spacing: 10) {
            SectionHeader("Maintenance") {
                addButton { showLogMaintenance = true }
            }
            CremaCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Equipment Health")
                            .font(.crema(15, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                        Spacer()
                        Text("\(healthScore)%")
                            .font(.crema(20, .bold))
                            .foregroundStyle(healthTint)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(CremaColor.surface)
                            Capsule().fill(healthTint)
                                .frame(width: geo.size.width * CGFloat(healthScore) / 100)
                        }
                    }
                    .frame(height: 10)
                    Text(healthCaption)
                        .font(.crema(13, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
            }
            if logs.isEmpty {
                emptyHint("Log backflushes, descales and filter changes to keep your machine healthy.")
            } else {
                ForEach(logs.prefix(8)) { log in
                    CremaCard {
                        HStack(spacing: 14) {
                            iconBadge(log.kind.systemImage)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(log.kind.rawValue)
                                    .font(.crema(15, .bold))
                                    .foregroundStyle(CremaColor.textPrimary)
                                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.crema(13, .medium))
                                    .foregroundStyle(CremaColor.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Text(log.isOverdue ? "Due" : "Next " + log.nextDue.formatted(.dateTime.month().day()))
                                .font(.crema(12, .semibold))
                                .foregroundStyle(log.isOverdue ? CremaColor.negative : CremaColor.positive)
                        }
                    }
                }
            }
        }
    }

    // MARK: Health score

    private var healthScore: Int {
        let kinds: [MaintenanceKind] = [.backflush, .descale, .waterFilter]
        guard !logs.isEmpty else { return 70 }
        let overdue = kinds.filter { kind in
            guard let last = logs.first(where: { $0.kind == kind }) else { return true }
            return last.isOverdue
        }.count
        return max(20, 100 - overdue * 25)
    }
    private var healthTint: Color {
        switch healthScore {
        case 80...100: return CremaColor.positive
        case 50..<80: return CremaColor.warning
        default: return CremaColor.negative
        }
    }
    private var healthCaption: String {
        switch healthScore {
        case 80...100: return "Your machine is in great shape."
        case 50..<80: return "A couple of maintenance tasks are coming due."
        default: return "Maintenance is overdue — log a backflush or descale."
        }
    }

    // MARK: Helpers

    private func iconBadge(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.crema(18))
            .foregroundStyle(CremaColor.crema)
            .frame(width: 44, height: 44)
            .background(CremaColor.surface)
            .clipShape(.rect(cornerRadius: 12))
    }

    private func addButton(_ action: @escaping () -> Void) -> some View {
        Button {
            HapticEngine.tap(); action()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.crema(22))
                .foregroundStyle(CremaColor.espresso)
        }
    }

    private func deleteMachine(_ machine: Machine) {
        // Brew / DialedRecipe relationships are nullified, maintenance logs and
        // reminders cascade. Journal history that referenced this machine is kept.
        modelContext.delete(machine)
        HapticEngine.warning()
    }

    private func deleteGrinder(_ grinder: Grinder) {
        // Brew / DialedRecipe relationships are nullified, so journal history is
        // preserved while the grinder is removed.
        modelContext.delete(grinder)
        HapticEngine.warning()
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.crema(14))
            .foregroundStyle(CremaColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}
