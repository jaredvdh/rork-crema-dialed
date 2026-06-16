//
//  AppPreferencesView.swift
//  CremaDialed
//
//  Every app-wide behaviour setting in one place: measurement units,
//  temperature, weight and volume, appearance, haptics, notifications and
//  location. Measurement values are always stored in metric / Celsius / grams /
//  millilitres — these preferences only change how they are displayed.
//

import SwiftUI
import UIKit
import CoreLocation
import UserNotifications

struct AppPreferencesView: View {
    @AppStorage(UnitPreferences.systemKey) private var systemRaw: String = MeasurementSystem.metric.rawValue
    @AppStorage(UnitPreferences.temperatureKey) private var temperatureRaw: String = TemperatureUnit.celsius.rawValue
    @AppStorage(UnitPreferences.weightKey) private var weightRaw: String = WeightUnit.grams.rawValue
    @AppStorage(UnitPreferences.volumeKey) private var volumeRaw: String = VolumeUnit.millilitres.rawValue

    @AppStorage(AppSettings.appearanceKey) private var appearanceRaw: String = AppearanceMode.system.rawValue
    @AppStorage(AppSettings.hapticsKey) private var hapticsEnabled: Bool = true
    @AppStorage(AppSettings.notificationsKey) private var notificationsEnabled: Bool = false
    @AppStorage(AppSettings.locationKey) private var locationEnabled: Bool = true

    @State private var locationManager = CLLocationManager()
    @State private var showLocationSettingsAlert = false

    private var system: MeasurementSystem { MeasurementSystem(rawValue: systemRaw) ?? .metric }
    private var temperature: TemperatureUnit { TemperatureUnit(rawValue: temperatureRaw) ?? .celsius }
    private var weight: WeightUnit { WeightUnit(rawValue: weightRaw) ?? .grams }
    private var volume: VolumeUnit { VolumeUnit(rawValue: volumeRaw) ?? .millilitres }
    private var appearance: AppearanceMode { AppearanceMode(rawValue: appearanceRaw) ?? .system }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectionTitle("Measurement")
                unitsCard
                temperatureCard
                weightCard
                volumeCard

                sectionTitle("Appearance")
                appearanceCard

                sectionTitle("Behaviour")
                hapticsCard
                notificationsCard
                locationCard

                footer
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle("App Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Location is Off", isPresented: $showLocationSettingsAlert) {
            Button("Open Settings") { openSystemSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To find cafés near you, allow location access for Crema Dialed in the system Settings.")
        }
    }

    // MARK: Measurement cards

    private var unitsCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Units", systemImage: "ruler.fill",
                           subtitle: "Distance for café discovery")
                segmented(options: MeasurementSystem.allCases,
                          selection: system,
                          label: { $0.label },
                          caption: { $0.caption }) { systemRaw = $0.rawValue }
            }
        }
    }

    private var temperatureCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Temperature", systemImage: "thermometer.medium",
                           subtitle: "Brew water temperature unit")
                segmented(options: TemperatureUnit.allCases,
                          selection: temperature,
                          label: { $0.label },
                          caption: { $0.symbol }) { temperatureRaw = $0.rawValue }
            }
        }
    }

    private var weightCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Weight", systemImage: "scalemass.fill",
                           subtitle: "Dose and yield measurements")
                segmented(options: WeightUnit.allCases,
                          selection: weight,
                          label: { $0.label },
                          caption: { $0.symbol }) { weightRaw = $0.rawValue }
            }
        }
    }

    private var volumeCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Volume", systemImage: "drop.fill",
                           subtitle: "Water and liquid measurements")
                segmented(options: VolumeUnit.allCases,
                          selection: volume,
                          label: { $0.label },
                          caption: { $0.symbol }) { volumeRaw = $0.rawValue }
            }
        }
    }

    // MARK: Appearance

    private var appearanceCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader("Theme", systemImage: "paintbrush.fill",
                           subtitle: "Light, dark or follow the system")
                segmented(options: AppearanceMode.allCases,
                          selection: appearance,
                          label: { $0.label },
                          caption: { _ in "" }) { selected in
                    appearanceRaw = selected.rawValue
                }
            }
        }
    }

    // MARK: Behaviour toggles

    private var hapticsCard: some View {
        toggleCard("Haptics", systemImage: "hand.tap.fill",
                   subtitle: "Vibration feedback on actions",
                   isOn: $hapticsEnabled)
    }

    private var notificationsCard: some View {
        toggleCard("Notifications", systemImage: "bell.fill",
                   subtitle: "Maintenance reminders and alerts",
                   isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in
                        notificationsEnabled = newValue
                        if newValue { requestNotificationAuthorization() }
                    }))
    }

    private var locationCard: some View {
        toggleCard("Location Services", systemImage: "location.fill",
                   subtitle: "Nearby cafés, Coffee Passport and check-ins",
                   isOn: Binding(
                    get: { locationEnabled },
                    set: { newValue in
                        locationEnabled = newValue
                        if newValue { handleLocationEnable() }
                    }))
    }

    private var footer: some View {
        Text("Measurements are stored consistently — switching units only changes how they're displayed.")
            .font(.crema(13, .medium))
            .foregroundStyle(CremaColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    // MARK: Side effects

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    private func handleLocationEnable() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            showLocationSettingsAlert = true
        default:
            break
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Building blocks

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.crema(12, .semibold))
            .foregroundStyle(CremaColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

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

    private func toggleCard(_ title: String, systemImage: String, subtitle: String,
                            isOn: Binding<Bool>) -> some View {
        CremaCard {
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
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(CremaColor.crema)
            }
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
                let captionText = caption(option)
                Button {
                    HapticEngine.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) { onSelect(option) }
                } label: {
                    VStack(spacing: 3) {
                        Text(label(option))
                            .font(.crema(15, .semibold))
                        if !captionText.isEmpty {
                            Text(captionText)
                                .font(.crema(11, .medium))
                                .opacity(0.8)
                        }
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
