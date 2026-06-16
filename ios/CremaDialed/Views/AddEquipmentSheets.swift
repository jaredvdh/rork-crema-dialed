//
//  AddEquipmentSheets.swift
//  CremaDialed
//

import SwiftUI

struct AddMachineSheet: View {
    var onSave: (Machine) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var manufacturer = ""
    @State private var model = ""
    @State private var boiler: BoilerType = .singleBoiler
    @State private var pump: PumpType = .vibratory
    @State private var group: GroupHeadType = .e61
    @State private var integratedGrinder = false

    private var canSave: Bool {
        !manufacturer.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader("Popular Machines")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(EquipmentCatalog.machines) { t in
                                CremaChip(label: t.displayName, isSelected: false) {
                                    manufacturer = t.manufacturer; model = t.model
                                    boiler = t.boiler; pump = t.pump; group = t.group
                                    integratedGrinder = t.integratedGrinder
                                }
                            }
                        }
                    }

                    CremaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledField(label: "Manufacturer", text: $manufacturer, placeholder: "Breville")
                            Divider().overlay(CremaColor.separator)
                            LabeledField(label: "Model", text: $model, placeholder: "Barista Express")
                        }
                    }
                    CremaCard {
                        VStack(alignment: .leading, spacing: 14) {
                            EnumPicker(label: "Boiler", selection: $boiler)
                            EnumPicker(label: "Pump", selection: $pump)
                            EnumPicker(label: "Group Head", selection: $group)
                            Toggle(isOn: $integratedGrinder) {
                                Text("Integrated grinder")
                                    .font(.crema(15, .medium))
                                    .foregroundStyle(CremaColor.textPrimary)
                            }
                            .tint(CremaColor.crema)
                        }
                    }
                }
                .padding(16)
            }
            .background(CremaColor.background)
            .navigationTitle("Add Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Machine(manufacturer: manufacturer.trimmingCharacters(in: .whitespaces),
                                       model: model.trimmingCharacters(in: .whitespaces),
                                       boilerType: boiler, pumpType: pump, groupHead: group,
                                       hasIntegratedGrinder: integratedGrinder))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

struct AddGrinderSheet: View {
    var onSave: (Grinder) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var manufacturer = ""
    @State private var model = ""
    @State private var kind: GrinderKind = .stepped
    @State private var burr: BurrType = .conical
    @State private var burrSize = 54
    @State private var referencePoint = ""

    private var canSave: Bool {
        !manufacturer.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader("Popular Grinders")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(EquipmentCatalog.grinders) { t in
                                CremaChip(label: t.displayName, isSelected: false) {
                                    manufacturer = t.manufacturer; model = t.model
                                    kind = t.kind; burr = t.burr; burrSize = t.burrSize
                                }
                            }
                        }
                    }

                    CremaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledField(label: "Manufacturer", text: $manufacturer, placeholder: "Niche")
                            Divider().overlay(CremaColor.separator)
                            LabeledField(label: "Model", text: $model, placeholder: "Zero")
                        }
                    }
                    CremaCard {
                        VStack(alignment: .leading, spacing: 14) {
                            EnumPicker(label: "Type", selection: $kind)
                            Text(kind.detail)
                                .font(.crema(12, .medium))
                                .foregroundStyle(CremaColor.textTertiary)
                            EnumPicker(label: "Burr", selection: $burr)
                            HStack {
                                Text("Burr Size")
                                    .font(.crema(15, .medium))
                                    .foregroundStyle(CremaColor.textPrimary)
                                Spacer()
                                Text("\(burrSize)mm")
                                    .font(.crema(15, .semibold))
                                    .foregroundStyle(CremaColor.crema)
                                Stepper("", value: $burrSize, in: 30...100, step: 1).labelsHidden()
                            }
                            if kind == .stepless {
                                Divider().overlay(CremaColor.separator)
                                LabeledField(label: "Reference Point", text: $referencePoint, placeholder: "e.g. zero chirp")
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(CremaColor.background)
            .navigationTitle("Add Grinder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Grinder(manufacturer: manufacturer.trimmingCharacters(in: .whitespaces),
                                       model: model.trimmingCharacters(in: .whitespaces),
                                       kind: kind, burrType: burr, burrSizeMM: burrSize,
                                       referencePoint: referencePoint))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

struct LogMaintenanceSheet: View {
    let machines: [Machine]
    var onSave: (MaintenanceLog) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var kind: MaintenanceKind = .backflush
    @State private var machine: Machine?
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader("Task")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(MaintenanceKind.allCases) { k in
                            Button {
                                HapticEngine.selection(); kind = k
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: k.systemImage)
                                    Text(k.rawValue)
                                        .font(.crema(14, .semibold))
                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .foregroundStyle(kind == k ? CremaColor.background : CremaColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .background(kind == k ? CremaColor.espresso : CremaColor.surface)
                                .clipShape(.rect(cornerRadius: CremaRadius.field))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }

                    CremaCard {
                        VStack(alignment: .leading, spacing: 14) {
                            if !machines.isEmpty {
                                HStack {
                                    Text("Machine")
                                        .font(.crema(15, .medium))
                                        .foregroundStyle(CremaColor.textPrimary)
                                    Spacer()
                                    Picker("", selection: $machine) {
                                        Text("None").tag(Machine?.none)
                                        ForEach(machines) { m in
                                            Text(m.displayName).tag(Machine?.some(m))
                                        }
                                    }
                                    .tint(CremaColor.espresso)
                                }
                            }
                            DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                                .font(.crema(15, .medium))
                                .tint(CremaColor.crema)
                        }
                    }
                    CremaCard { LabeledField(label: "Notes", text: $notes, placeholder: "Optional", axis: .vertical) }
                }
                .padding(16)
            }
            .background(CremaColor.background)
            .navigationTitle("Log Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(MaintenanceLog(kind: kind, machine: machine, date: date, notes: notes))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Generic picker for CaseIterable enums with a RawValue of String.
struct EnumPicker<T: CaseIterable & Identifiable & RawRepresentable & Hashable>: View where T.RawValue == String, T.AllCases: RandomAccessCollection {
    let label: String
    @Binding var selection: T

    var body: some View {
        HStack {
            Text(label)
                .font(.crema(15, .medium))
                .foregroundStyle(CremaColor.textPrimary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(T.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .tint(CremaColor.espresso)
        }
    }
}
