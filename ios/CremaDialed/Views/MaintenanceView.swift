//
//  MaintenanceView.swift
//  CremaDialed
//
//  Per-machine maintenance hub: reminder cards driven by time or coffees pulled,
//  one-tap completion, a full history log, and machine-specific care notes.
//

import SwiftUI
import SwiftData

struct MaintenanceView: View {
    @Bindable var machine: Machine
    var hasGrinder: Bool

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceLog.date, order: .reverse) private var allLogs: [MaintenanceLog]
    @Query(sort: \Brew.date, order: .reverse) private var allBrews: [Brew]

    @State private var configuringKind: MaintenanceKind?
    @State private var showNotes = false

    private var logs: [MaintenanceLog] {
        allLogs.filter { $0.machine?.id == machine.id }
    }
    private var machineBrews: [Brew] {
        allBrews.filter { $0.machine?.id == machine.id }
    }

    private var kinds: [MaintenanceKind] {
        MaintenanceEngine.applicableKinds(hasGrinder: hasGrinder)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                healthHeader
                remindersSection
                notesSection
                historySection
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle("Maintenance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $configuringKind) { kind in
            ReminderConfigSheet(kind: kind, reminder: reminder(for: kind)) { mode, days, shots in
                applyReminder(kind: kind, mode: mode, days: days, shots: shots)
            }
        }
    }

    // MARK: Health header

    private var dueStatuses: [MaintenanceStatus] {
        kinds.map { status(for: $0) }
    }
    private var dueCount: Int { dueStatuses.filter(\.isDue).count }
    private var healthScore: Int {
        let tracked = dueStatuses.filter { $0.mode != .off }
        guard !tracked.isEmpty else { return 100 }
        let due = tracked.filter(\.isDue).count
        return max(10, 100 - Int(Double(due) / Double(tracked.count) * 100))
    }
    private var healthTint: Color {
        switch healthScore {
        case 80...100: return CremaColor.positive
        case 45..<80: return CremaColor.warning
        default: return CremaColor.negative
        }
    }

    private var healthHeader: some View {
        CremaCard {
            HStack(spacing: 18) {
                ZStack {
                    Circle().stroke(CremaColor.surface, lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: CGFloat(healthScore) / 100)
                        .stroke(healthTint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: healthScore)
                    VStack(spacing: 0) {
                        Text("\(healthScore)")
                            .font(.crema(24, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                            .contentTransition(.numericText())
                        Text("HEALTH")
                            .font(.crema(8, .semibold))
                            .foregroundStyle(CremaColor.textTertiary)
                    }
                }
                .frame(width: 78, height: 78)

                VStack(alignment: .leading, spacing: 4) {
                    Text(machine.displayName)
                        .font(.crema(18, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                    Text(dueCount == 0
                         ? "Everything is up to date."
                         : "\(dueCount) task\(dueCount == 1 ? "" : "s") need attention.")
                        .font(.crema(14, .medium))
                        .foregroundStyle(dueCount == 0 ? CremaColor.positive : CremaColor.warning)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Reminders

    private var remindersSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Care Tasks")
            ForEach(kinds) { kind in
                reminderCard(kind)
            }
        }
    }

    private func reminderCard(_ kind: MaintenanceKind) -> some View {
        let s = status(for: kind)
        return CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: kind.systemImage)
                        .font(.crema(18))
                        .foregroundStyle(s.isDue ? CremaColor.background : CremaColor.crema)
                        .frame(width: 44, height: 44)
                        .background(s.isDue ? CremaColor.warning : CremaColor.surface)
                        .clipShape(.rect(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.rawValue)
                            .font(.crema(16, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                        Text(kind.detail)
                            .font(.crema(12, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Button {
                        HapticEngine.light()
                        configuringKind = kind
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.crema(15))
                            .foregroundStyle(CremaColor.textTertiary)
                    }
                }

                if s.mode != .off {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(CremaColor.surface)
                            Capsule().fill(s.isDue ? CremaColor.warning : CremaColor.crema)
                                .frame(width: geo.size.width * CGFloat(min(1, s.progress)))
                        }
                    }
                    .frame(height: 8)
                }

                HStack {
                    Text(s.summary)
                        .font(.crema(13, .semibold))
                        .foregroundStyle(s.isDue ? CremaColor.warning : CremaColor.textSecondary)
                    Spacer()
                    Button {
                        markDone(kind)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Mark Done")
                        }
                        .font(.crema(14, .bold))
                        .foregroundStyle(CremaColor.background)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(CremaColor.espresso)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(spacing: 12) {
            SectionHeader("Machine Notes")
            CremaCard {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(label: "Water Hardness", text: $machine.waterHardness, placeholder: "e.g. 50 ppm / soft")
                    Divider().overlay(CremaColor.separator)
                    LabeledField(label: "Preferred Cleaning Product", text: $machine.preferredCleaningProduct, placeholder: "e.g. Cafiza")
                    Divider().overlay(CremaColor.separator)
                    HStack {
                        Text("LAST SERVICE")
                            .font(.crema(11, .semibold))
                            .foregroundStyle(CremaColor.textTertiary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { machine.lastServiceDate != nil },
                            set: { machine.lastServiceDate = $0 ? Date() : nil }
                        ))
                        .labelsHidden()
                        .tint(CremaColor.crema)
                    }
                    if machine.lastServiceDate != nil {
                        DatePicker("Date", selection: Binding(
                            get: { machine.lastServiceDate ?? Date() },
                            set: { machine.lastServiceDate = $0 }
                        ), in: ...Date(), displayedComponents: .date)
                        .font(.crema(15, .medium))
                        .tint(CremaColor.crema)
                    }
                    Divider().overlay(CremaColor.separator)
                    LabeledField(label: "Manufacturer Recommendations", text: $machine.manufacturerRecommendations,
                                 placeholder: "e.g. descale every 3 months", axis: .vertical)
                    Divider().overlay(CremaColor.separator)
                    LabeledField(label: "Notes", text: $machine.maintenanceNotes,
                                 placeholder: "Anything worth remembering…", axis: .vertical)
                }
            }
        }
    }

    // MARK: History

    private var historySection: some View {
        VStack(spacing: 12) {
            SectionHeader("History")
            if logs.isEmpty {
                Text("No maintenance logged yet. Mark a task done to start your history.")
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(logs) { log in
                    CremaCard {
                        HStack(spacing: 14) {
                            Image(systemName: log.kind.systemImage)
                                .font(.crema(16))
                                .foregroundStyle(CremaColor.crema)
                                .frame(width: 40, height: 40)
                                .background(CremaColor.surface)
                                .clipShape(.rect(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.kind.rawValue)
                                    .font(.crema(15, .bold))
                                    .foregroundStyle(CremaColor.textPrimary)
                                if !log.notes.isEmpty {
                                    Text(log.notes)
                                        .font(.crema(12, .medium))
                                        .foregroundStyle(CremaColor.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.crema(12, .semibold))
                                .foregroundStyle(CremaColor.textTertiary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            modelContext.delete(log)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
    }

    // MARK: Logic

    private func reminder(for kind: MaintenanceKind) -> MaintenanceReminder? {
        machine.maintenanceReminders.first { $0.kind == kind }
    }

    private func status(for kind: MaintenanceKind) -> MaintenanceStatus {
        let r = reminder(for: kind)
        let mode = r?.mode ?? kind.defaultMode
        let days = r?.intervalDays ?? kind.intervalDays
        let shots = r?.intervalShots ?? kind.intervalShots
        let last = logs.first(where: { $0.kind == kind })?.date
        let shotsSince: Int
        if let last {
            shotsSince = machineBrews.filter { $0.date >= last }.count
        } else {
            shotsSince = machineBrews.count
        }
        return MaintenanceEngine.status(kind: kind, mode: mode, intervalDays: days,
                                        intervalShots: shots, lastDone: last, shotsSince: shotsSince)
    }

    private func markDone(_ kind: MaintenanceKind) {
        HapticEngine.success()
        modelContext.insert(MaintenanceLog(kind: kind, machine: machine, date: Date()))
        if kind == .servicing { machine.lastServiceDate = Date() }
    }

    private func applyReminder(kind: MaintenanceKind, mode: MaintenanceFrequencyMode, days: Int, shots: Int) {
        if let existing = reminder(for: kind) {
            existing.mode = mode
            existing.intervalDays = days
            existing.intervalShots = shots
        } else {
            let r = MaintenanceReminder(machine: machine, kind: kind, mode: mode,
                                        intervalDays: days, intervalShots: shots)
            modelContext.insert(r)
        }
        HapticEngine.selection()
    }
}

/// Sheet to choose how a task reminds — by time, by coffees, or off.
private struct ReminderConfigSheet: View {
    let kind: MaintenanceKind
    let reminder: MaintenanceReminder?
    var onSave: (MaintenanceFrequencyMode, Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: MaintenanceFrequencyMode
    @State private var days: Double
    @State private var shots: Double

    init(kind: MaintenanceKind, reminder: MaintenanceReminder?,
         onSave: @escaping (MaintenanceFrequencyMode, Int, Int) -> Void) {
        self.kind = kind
        self.reminder = reminder
        self.onSave = onSave
        _mode = State(initialValue: reminder?.mode ?? kind.defaultMode)
        _days = State(initialValue: Double(reminder?.intervalDays ?? kind.intervalDays))
        _shots = State(initialValue: Double(reminder?.intervalShots ?? kind.intervalShots))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CremaCard {
                        HStack(spacing: 14) {
                            Image(systemName: kind.systemImage)
                                .font(.crema(20))
                                .foregroundStyle(CremaColor.crema)
                                .frame(width: 48, height: 48)
                                .background(CremaColor.surface)
                                .clipShape(.rect(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.rawValue)
                                    .font(.crema(17, .bold))
                                    .foregroundStyle(CremaColor.textPrimary)
                                Text(kind.detail)
                                    .font(.crema(13, .medium))
                                    .foregroundStyle(CremaColor.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }

                    CremaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("REMIND ME")
                                .font(.crema(11, .semibold))
                                .foregroundStyle(CremaColor.textTertiary)
                            Picker("", selection: $mode) {
                                ForEach(MaintenanceFrequencyMode.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    if mode == .time {
                        intervalCard(title: "Every", value: $days, unit: "days", range: 1...365, step: 1)
                    } else if mode == .shots {
                        intervalCard(title: "Every", value: $shots, unit: "coffees", range: 5...2000, step: 5)
                    } else {
                        CremaCard {
                            Text("This task will appear in your history but won't show a reminder.")
                                .font(.crema(14, .medium))
                                .foregroundStyle(CremaColor.textSecondary)
                        }
                    }
                }
                .padding(16)
            }
            .background(CremaColor.background)
            .navigationTitle("Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(mode, Int(days), Int(shots))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func intervalCard(title: String, value: Binding<Double>, unit: String,
                              range: ClosedRange<Double>, step: Double) -> some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(title)
                        .font(.crema(15, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                    Text("\(Int(value.wrappedValue))")
                        .font(.crema(28, .bold))
                        .foregroundStyle(CremaColor.crema)
                        .contentTransition(.numericText())
                    Text(unit)
                        .font(.crema(15, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
                Slider(value: value, in: range, step: step)
                    .tint(CremaColor.crema)
            }
        }
    }
}
