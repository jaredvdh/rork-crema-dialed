//
//  AboutView.swift
//  CremaDialed
//
//  Version, build and the support / legal links for the app.
//

import SwiftUI
import UIKit

struct AboutView: View {
    private let supportEmail = "support@cremadialed.app"
    private let appStoreID = "6780824712"

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                infoCard
                supportSection
                legalSection
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(CremaColor.background)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(CremaColor.background)
                .frame(width: 84, height: 84)
                .background(CremaColor.espresso)
                .clipShape(.rect(cornerRadius: 22))
            Text("Crema Dialed")
                .font(.crema(22, .bold))
                .foregroundStyle(CremaColor.textPrimary)
            Text("Dial in the perfect shot, every time.")
                .font(.crema(14, .medium))
                .foregroundStyle(CremaColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var infoCard: some View {
        CremaCard {
            VStack(spacing: 0) {
                infoRow("Version", value: version)
                Divider().overlay(CremaColor.separator)
                infoRow("Build", value: build)
            }
        }
    }

    private var supportSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Support")
            linkRow("Contact Support", icon: "envelope.fill",
                    url: URL(string: "mailto:\(supportEmail)?subject=Crema%20Dialed%20Support"))
            linkRow("Feature Requests", icon: "lightbulb.fill",
                    url: URL(string: "mailto:\(supportEmail)?subject=Crema%20Dialed%20Feature%20Request"))
            linkRow("Rate App", icon: "star.fill",
                    url: URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review"))
        }
    }

    private var legalSection: some View {
        VStack(spacing: 12) {
            sectionTitle("Legal")
            linkRow("Privacy Policy", icon: "lock.fill",
                    url: URL(string: "https://www-cremadialed-app.rork.app/#privacy"))
            linkRow("Terms of Service", icon: "doc.text.fill",
                    url: URL(string: "https://www-cremadialed-app.rork.app/#terms"))
        }
    }

    // MARK: Building blocks

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.crema(12, .semibold))
            .foregroundStyle(CremaColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.crema(16, .semibold))
                .foregroundStyle(CremaColor.textPrimary)
            Spacer()
            Text(value)
                .font(.crema(16, .medium))
                .foregroundStyle(CremaColor.textSecondary)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func linkRow(_ title: String, icon: String, url: URL?) -> some View {
        Button {
            HapticEngine.light()
            if let url { UIApplication.shared.open(url) }
        } label: {
            CremaCard {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.crema(17))
                        .foregroundStyle(CremaColor.crema)
                        .frame(width: 40, height: 40)
                        .background(CremaColor.surface)
                        .clipShape(.rect(cornerRadius: 12))
                    Text(title)
                        .font(.crema(16, .semibold))
                        .foregroundStyle(CremaColor.textPrimary)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.crema(13, .semibold))
                        .foregroundStyle(CremaColor.textTertiary)
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}
