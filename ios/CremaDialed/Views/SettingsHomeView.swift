//
//  SettingsHomeView.swift
//  CremaDialed
//
//  The single home for every configuration surface in Crema Dialed. Equipment,
//  app behaviour, maintenance, backups and app information all live here behind
//  one set of grouped cards, so nothing has to be hunted for in the workflow.
//

import SwiftUI

/// Destinations reachable from the Settings home.
enum SettingsRoute: Hashable {
    case equipment
    case appPreferences
    case maintenance
    case dataBackup
    case about
}

struct SettingsHomeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        card(.equipment,
                             icon: "cup.and.saucer.fill",
                             tint: CremaColor.espresso,
                             title: "Equipment",
                             subtitle: "Manage machines, grinders and active setup")
                        card(.appPreferences,
                             icon: "slider.horizontal.3",
                             tint: CremaColor.crema,
                             title: "App Preferences",
                             subtitle: "Units, theme and notifications")
                        card(.maintenance,
                             icon: "wrench.and.screwdriver.fill",
                             tint: CremaColor.caramel,
                             title: "Maintenance",
                             subtitle: "Cleaning schedules and reminders")
                        card(.dataBackup,
                             icon: "externaldrive.fill.badge.icloud",
                             tint: CremaColor.positive,
                             title: "Data & Backup",
                             subtitle: "Protect your coffee journey")
                        card(.about,
                             icon: "info.circle.fill",
                             tint: CremaColor.textSecondary,
                             title: "About",
                             subtitle: "Support and app information")
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { HapticEngine.light(); dismiss() }
                        .font(.crema(16, .semibold))
                        .foregroundStyle(CremaColor.espresso)
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .equipment: EquipmentView()
                case .appPreferences: AppPreferencesView()
                case .maintenance: MaintenanceHomeView()
                case .dataBackup: DataBackupView()
                case .about: AboutView()
                }
            }
            .navigationDestination(for: MachineRoute.self) { machineRoute in
                MaintenanceDestination(machineID: machineRoute.id)
            }
        }
    }

    private func card(_ route: SettingsRoute, icon: String, tint: Color,
                      title: String, subtitle: String) -> some View {
        NavigationLink(value: route) {
            CremaCard {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.crema(20))
                        .foregroundStyle(tint)
                        .frame(width: 48, height: 48)
                        .background(tint.opacity(0.14))
                        .clipShape(.rect(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.crema(17, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                        Text(subtitle)
                            .font(.crema(13, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.crema(14, .semibold))
                        .foregroundStyle(CremaColor.textTertiary)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// A type-safe route to a specific machine's maintenance hub, used so the
/// Equipment and Maintenance sections can push the same destination through the
/// shared Settings navigation stack.
struct MachineRoute: Hashable {
    let id: UUID
}
