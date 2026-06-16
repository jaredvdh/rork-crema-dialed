//
//  DataBackupView.swift
//  CremaDialed
//
//  Protect the coffee journey: sync preference, on-demand backups, and full
//  export / import of beans, dial-in history, the Coffee Passport, check-ins
//  and equipment as a portable JSON file.
//

import SwiftUI
import UIKit
import SwiftData
import UniformTypeIdentifiers

struct DataBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.iCloudSyncKey) private var iCloudSyncEnabled: Bool = false

    @State private var exportURL: IdentifiableURL?
    @State private var showImporter = false
    @State private var resultMessage: String?
    @State private var resultTitle = ""
    @State private var showResult = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                syncSection
                backupSection
                exportSection
                includedNote
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle("Data & Backup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportURL) { item in
            ShareSheet(items: [item.url])
        }
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.json, backupType],
                      allowsMultipleSelection: false) { result in
            handleImport(result)
        }
        .alert(resultTitle, isPresented: $showResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultMessage ?? "")
        }
    }

    // MARK: Sync

    private var syncSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Sync")
            CremaCard {
                HStack(spacing: 12) {
                    iconBadge("icloud.fill", tint: CremaColor.crema)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(.crema(17, .bold))
                            .foregroundStyle(CremaColor.textPrimary)
                        Text("Keep this device backed up to your iCloud account")
                            .font(.crema(13, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Toggle("", isOn: $iCloudSyncEnabled)
                        .labelsHidden()
                        .tint(CremaColor.crema)
                }
            }
        }
    }

    // MARK: Backup

    private var backupSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Backup")
            actionRow("Backup Now", subtitle: "Save a snapshot you can store anywhere",
                      icon: "arrow.down.doc.fill", tint: CremaColor.positive) {
                exportBackup()
            }
            actionRow("Restore Backup", subtitle: "Recover from a saved backup file",
                      icon: "arrow.uturn.backward.circle.fill", tint: CremaColor.caramel) {
                showImporter = true
            }
        }
    }

    // MARK: Export / import

    private var exportSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Transfer")
            actionRow("Export Data", subtitle: "Share your full coffee data as a file",
                      icon: "square.and.arrow.up.fill", tint: CremaColor.espresso) {
                exportBackup()
            }
            actionRow("Import Data", subtitle: "Bring data in from another device",
                      icon: "square.and.arrow.down.fill", tint: CremaColor.espresso) {
                showImporter = true
            }
        }
    }

    private var includedNote: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT'S INCLUDED")
                    .font(.crema(11, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
                ForEach(["Beans", "Dial-In History", "Coffee Passport", "Check-Ins", "Equipment"], id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle.fill")
                        .font(.crema(14, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
                Text("Photos are not included to keep backups small and shareable.")
                    .font(.crema(12, .medium))
                    .foregroundStyle(CremaColor.textTertiary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: Logic

    private func exportBackup() {
        HapticEngine.tap()
        let backup = BackupService.makeBackup(context: modelContext)
        do {
            let url = try BackupService.writeBackupFile(backup)
            exportURL = IdentifiableURL(url: url)
        } catch {
            present(title: "Export Failed",
                    message: "We couldn't create the backup file. Please try again.")
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importBackup(from: url)
        case .failure:
            present(title: "Import Cancelled", message: "No file was imported.")
        }
    }

    private func importBackup(from url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let backup = try BackupService.decoder().decode(CremaBackup.self, from: data)
            let summary = BackupService.restore(backup, into: modelContext)
            HapticEngine.success()
            if summary.total == 0 {
                present(title: "Already Up To Date",
                        message: "Everything in that backup is already on this device.")
            } else {
                present(title: "Import Complete", message: summaryMessage(summary))
            }
        } catch {
            present(title: "Import Failed",
                    message: "That file isn't a valid Crema Dialed backup.")
        }
    }

    private func summaryMessage(_ s: ImportSummary) -> String {
        var lines: [String] = []
        if s.beans > 0 { lines.append("\(s.beans) bean\(s.beans == 1 ? "" : "s")") }
        if s.machines > 0 { lines.append("\(s.machines) machine\(s.machines == 1 ? "" : "s")") }
        if s.grinders > 0 { lines.append("\(s.grinders) grinder\(s.grinders == 1 ? "" : "s")") }
        if s.brews > 0 { lines.append("\(s.brews) shot\(s.brews == 1 ? "" : "s")") }
        if s.recipes > 0 { lines.append("\(s.recipes) recipe\(s.recipes == 1 ? "" : "s")") }
        if s.cafes > 0 { lines.append("\(s.cafes) café\(s.cafes == 1 ? "" : "s")") }
        if s.visits > 0 { lines.append("\(s.visits) check-in\(s.visits == 1 ? "" : "s")") }
        return "Added " + lines.joined(separator: ", ") + "."
    }

    private func present(title: String, message: String) {
        resultTitle = title
        resultMessage = message
        showResult = true
    }

    // MARK: Building blocks

    private var backupType: UTType {
        UTType(filenameExtension: "cremabackup") ?? .json
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.crema(12, .semibold))
            .foregroundStyle(CremaColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func iconBadge(_ symbol: String, tint: Color) -> some View {
        Image(systemName: symbol)
            .font(.crema(18))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(tint.opacity(0.14))
            .clipShape(.rect(cornerRadius: 12))
    }

    private func actionRow(_ title: String, subtitle: String, icon: String, tint: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            CremaCard {
                HStack(spacing: 12) {
                    iconBadge(icon, tint: tint)
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
                    Image(systemName: "chevron.right")
                        .font(.crema(13, .semibold))
                        .foregroundStyle(CremaColor.textTertiary)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// Wraps a URL so it can drive a `.sheet(item:)`.
struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

/// Minimal share-sheet bridge for exporting backup files.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
