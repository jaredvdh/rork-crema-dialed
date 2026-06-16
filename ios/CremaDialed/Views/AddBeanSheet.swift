//
//  AddBeanSheet.swift
//  CremaDialed
//

import SwiftUI

struct AddBeanSheet: View {
    /// When set, the sheet edits this bean in place instead of creating a new one.
    var editing: Bean? = nil
    var onSave: (Bean) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var roaster = ""
    @State private var country = ""
    @State private var region = ""
    @State private var farm = ""
    @State private var variety = ""
    @State private var process: ProcessMethod = .washed
    @State private var roastLevel: RoastLevel = .medium
    @State private var hasRoastDate = true
    @State private var roastDate = Date()
    @State private var notes = ""
    @State private var photoData: Data?

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoPicker

                    fieldCard {
                        LabeledField(label: "Bean Name", text: $name, placeholder: "Ethiopia Guji")
                        Divider().overlay(CremaColor.separator)
                        LabeledField(label: "Roaster", text: $roaster, placeholder: "Onyx Coffee Lab")
                    }

                    fieldCard {
                        LabeledField(label: "Country", text: $country, placeholder: "Ethiopia")
                        Divider().overlay(CremaColor.separator)
                        LabeledField(label: "Region", text: $region, placeholder: "Guji")
                        Divider().overlay(CremaColor.separator)
                        LabeledField(label: "Farm", text: $farm, placeholder: "Optional")
                        Divider().overlay(CremaColor.separator)
                        LabeledField(label: "Variety", text: $variety, placeholder: "Heirloom")
                    }

                    CremaCard {
                        VStack(alignment: .leading, spacing: 14) {
                            pickerRow("Process") {
                                Picker("", selection: $process) {
                                    ForEach(ProcessMethod.allCases) { Text($0.rawValue).tag($0) }
                                }
                            }
                            pickerRow("Roast Level") {
                                Picker("", selection: $roastLevel) {
                                    ForEach(RoastLevel.allCases) { Text($0.rawValue).tag($0) }
                                }
                            }
                            Toggle(isOn: $hasRoastDate) {
                                Text("Known roast date")
                                    .font(.crema(15, .medium))
                                    .foregroundStyle(CremaColor.textPrimary)
                            }
                            .tint(CremaColor.crema)
                            if hasRoastDate {
                                DatePicker("Roast date", selection: $roastDate, in: ...Date(), displayedComponents: .date)
                                    .font(.crema(15, .medium))
                                    .tint(CremaColor.crema)
                            }
                        }
                    }

                    fieldCard {
                        LabeledField(label: "Notes", text: $notes, placeholder: "Tasting notes, intentions…", axis: .vertical)
                    }
                }
                .padding(16)
            }
            .background(CremaColor.background)
            .navigationTitle(editing == nil ? "New Bean" : "Edit Bean")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadEditing)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var photoPicker: some View {
        SinglePhotoCaptureField(photo: $photoData, emptyTitle: "Add bag photo")
    }

    private func fieldCard<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        CremaCard { VStack(alignment: .leading, spacing: 12) { content() } }
    }

    private func pickerRow<P: View>(_ label: String, @ViewBuilder _ picker: () -> P) -> some View {
        HStack {
            Text(label)
                .font(.crema(15, .medium))
                .foregroundStyle(CremaColor.textPrimary)
            Spacer()
            picker().tint(CremaColor.espresso)
        }
    }

    private func loadEditing() {
        guard let bean = editing, name.isEmpty else { return }
        name = bean.name
        roaster = bean.roaster
        country = bean.country
        region = bean.region
        farm = bean.farm
        variety = bean.variety
        process = bean.process
        roastLevel = bean.roastLevel
        hasRoastDate = bean.roastDate != nil
        roastDate = bean.roastDate ?? Date()
        notes = bean.notes
        photoData = bean.photoData
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let bean = editing {
            bean.name = trimmed
            bean.roaster = roaster
            bean.country = country
            bean.region = region
            bean.farm = farm
            bean.variety = variety
            bean.processRaw = process.rawValue
            bean.roastLevelRaw = roastLevel.rawValue
            bean.roastDate = hasRoastDate ? roastDate : nil
            bean.notes = notes
            bean.photoData = photoData
            onSave(bean)
            dismiss()
            return
        }
        let bean = Bean(
            name: trimmed,
            roaster: roaster,
            country: country,
            region: region,
            farm: farm,
            variety: variety,
            process: process,
            roastLevel: roastLevel,
            roastDate: hasRoastDate ? roastDate : nil,
            notes: notes,
            photoData: photoData
        )
        onSave(bean)
        dismiss()
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.crema(11, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
            TextField(placeholder, text: $text, axis: axis)
                .font(.crema(16, .medium))
                .foregroundStyle(CremaColor.textPrimary)
                .tint(CremaColor.crema)
        }
    }
}
