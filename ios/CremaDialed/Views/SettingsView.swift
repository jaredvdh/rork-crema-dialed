//
//  SettingsView.swift
//  CremaDialed
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UnitPreferences.systemKey) private var systemRaw: String = MeasurementSystem.metric.rawValue
    @AppStorage(UnitPreferences.temperatureKey) private var temperatureRaw: String = TemperatureUnit.celsius.rawValue

    private var system: MeasurementSystem { MeasurementSystem(rawValue: systemRaw) ?? .metric }
    private var temperature: TemperatureUnit { TemperatureUnit(rawValue: temperatureRaw) ?? .celsius }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        unitsCard
                        temperatureCard
                        footer
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { HapticEngine.light(); dismiss() }
                        .font(.crema(16, .semibold))
                        .foregroundStyle(CremaColor.espresso)
                }
            }
        }
    }

    // MARK: Distance units

    private var unitsCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Distance", systemImage: "location.fill",
                           subtitle: "How café distances are shown")
                segmented(options: MeasurementSystem.allCases,
                          selection: system,
                          label: { $0.label },
                          caption: { $0.caption }) { selected in
                    systemRaw = selected.rawValue
                }
            }
        }
    }

    // MARK: Temperature units

    private var temperatureCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Temperature", systemImage: "thermometer.medium",
                           subtitle: "Brew water temperature unit")
                segmented(options: TemperatureUnit.allCases,
                          selection: temperature,
                          label: { $0.label },
                          caption: { $0.symbol }) { selected in
                    temperatureRaw = selected.rawValue
                }
            }
        }
    }

    private var footer: some View {
        Text("Measurements are stored consistently — switching units only changes how they're displayed.")
            .font(.crema(13, .medium))
            .foregroundStyle(CremaColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    // MARK: Building blocks

    private func cardHeader(_ title: String, systemImage: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.crema(18))
                .foregroundStyle(CremaColor.crema)
                .frame(width: 40, height: 40)
                .background(CremaColor.surface)
                .clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.crema(17, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text(subtitle)
                    .font(.crema(13, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func segmented<Option: Identifiable & Equatable>(
        options: [Option],
        selection: Option,
        label: @escaping (Option) -> String,
        caption: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(options) { option in
                let isSelected = option == selection
                Button {
                    HapticEngine.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) { onSelect(option) }
                } label: {
                    VStack(spacing: 3) {
                        Text(label(option))
                            .font(.crema(15, .semibold))
                        Text(caption(option))
                            .font(.crema(11, .medium))
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(isSelected ? CremaColor.background : CremaColor.textSecondary)
                    .background(isSelected ? CremaColor.espresso : CremaColor.surface)
                    .clipShape(.rect(cornerRadius: CremaRadius.field))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}
