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
    @State private var search = ""
    @State private var selectedTemplate: MachineTemplate?
    @State private var showAllSpecs = false

    private var canSave: Bool {
        !manufacturer.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var groupedMatches: [(brand: String, items: [MachineTemplate])] {
        let q = search.trimmingCharacters(in: .whitespaces)
        let matches = q.isEmpty
            ? EquipmentCatalog.machines
            : EquipmentCatalog.machines.filter { $0.displayName.localizedCaseInsensitiveContains(q) }
        let brands = Dictionary(grouping: matches, by: { $0.manufacturer })
        return brands.keys.sorted().map { ($0, brands[$0]!.sorted { $0.model < $1.model }) }
    }

    private func apply(_ t: MachineTemplate) {
        manufacturer = t.manufacturer; model = t.model
        boiler = t.boiler; pump = t.pump; group = t.group
        integratedGrinder = t.integratedGrinder
        selectedTemplate = t
        showAllSpecs = true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    EquipmentSearchField(text: $search, placeholder: "Search machines & brands")

                    VStack(spacing: 10) {
                        ForEach(groupedMatches, id: \.brand) { group in
                            BrandGroup(brand: group.brand) {
                                ForEach(group.items) { t in
                                    EquipmentPickRow(
                                        title: t.model,
                                        subtitle: "\(t.boiler.rawValue) · \(t.pump.rawValue)\(t.integratedGrinder ? " · Built-in grinder" : "")",
                                        isSelected: selectedTemplate == t
                                    ) { apply(t) }
                                }
                            }
                        }
                        if groupedMatches.isEmpty {
                            Text("No matches — enter your machine manually below.")
                                .font(.crema(13, .medium))
                                .foregroundStyle(CremaColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SectionHeader("Or Enter Manually")
                    CremaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledField(label: "Manufacturer", text: $manufacturer, placeholder: "Breville")
                            Divider().overlay(CremaColor.separator)
                            LabeledField(label: "Model", text: $model, placeholder: "Barista Express")
                        }
                    }

                    DisclosureGroup(isExpanded: $showAllSpecs) {
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
                        .padding(.top, 8)
                    } label: {
                        Text("Specifications")
                            .font(.crema(15, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                    }
                    .tint(CremaColor.espresso)
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
    @State private var search = ""
    @State private var selectedTemplate: GrinderTemplate?
    @State private var showAllSpecs = false

    private var canSave: Bool {
        !manufacturer.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var groupedMatches: [(brand: String, items: [GrinderTemplate])] {
        let q = search.trimmingCharacters(in: .whitespaces)
        let matches = q.isEmpty
            ? EquipmentCatalog.grinders
            : EquipmentCatalog.grinders.filter { $0.displayName.localizedCaseInsensitiveContains(q) }
        let brands = Dictionary(grouping: matches, by: { $0.manufacturer })
        return brands.keys.sorted().map { ($0, brands[$0]!.sorted { $0.model < $1.model }) }
    }

    private func apply(_ t: GrinderTemplate) {
        manufacturer = t.manufacturer; model = t.model
        kind = t.kind; burr = t.burr; burrSize = t.burrSize
        selectedTemplate = t
        showAllSpecs = true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    EquipmentSearchField(text: $search, placeholder: "Search grinders & brands")

                    VStack(spacing: 10) {
                        ForEach(groupedMatches, id: \.brand) { group in
                            BrandGroup(brand: group.brand) {
                                ForEach(group.items) { t in
                                    EquipmentPickRow(
                                        title: t.model,
                                        subtitle: "\(t.kind.rawValue) · \(t.burr.rawValue) \(t.burrSize)mm",
                                        isSelected: selectedTemplate == t
                                    ) { apply(t) }
                                }
                            }
                        }
                        if groupedMatches.isEmpty {
                            Text("No matches — enter your grinder manually below.")
                                .font(.crema(13, .medium))
                                .foregroundStyle(CremaColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    SectionHeader("Or Enter Manually")
                    CremaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledField(label: "Manufacturer", text: $manufacturer, placeholder: "Niche")
                            Divider().overlay(CremaColor.separator)
                            LabeledField(label: "Model", text: $model, placeholder: "Zero")
                        }
                    }

                    DisclosureGroup(isExpanded: $showAllSpecs) {
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
                        .padding(.top, 8)
                    } label: {
                        Text("Specifications")
                            .font(.crema(15, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                    }
                    .tint(CremaColor.espresso)
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

/// Search field used to filter the equipment catalog.
struct EquipmentSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.crema(15, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            TextField(placeholder, text: $text)
                .font(.crema(15, .medium))
                .foregroundStyle(CremaColor.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button {
                    HapticEngine.tap(); text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.crema(15))
                        .foregroundStyle(CremaColor.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CremaColor.surface)
        .clipShape(.rect(cornerRadius: CremaRadius.field))
    }
}

/// A collapsible-style brand heading wrapping its model rows in a single card.
struct BrandGroup<Content: View>: View {
    let brand: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(brand.uppercased())
                .font(.crema(12, .bold))
                .foregroundStyle(CremaColor.textSecondary)
                .padding(.leading, 4)
            CremaCard {
                VStack(spacing: 0) { content }
            }
        }
    }
}

/// A single tappable equipment template row.
struct EquipmentPickRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticEngine.selection(); action()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.crema(15, .semibold))
                        .foregroundStyle(CremaColor.textPrimary)
                    Text(subtitle)
                        .font(.crema(12, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.crema(18))
                    .foregroundStyle(isSelected ? CremaColor.espresso : CremaColor.textTertiary)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
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
