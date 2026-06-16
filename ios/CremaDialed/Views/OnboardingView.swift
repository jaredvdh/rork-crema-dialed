//
//  OnboardingView.swift
//  CremaDialed
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var index: Int = 0

    private let pages: [OnboardingPage] = [
        .init(systemImage: "cup.and.saucer.fill", title: "Welcome to\nCrema Dialed", subtitle: "Your personal barista companion for consistently better espresso, shot after shot."),
        .init(systemImage: "gearshape.2.fill", title: "Your Equipment", subtitle: "Add your machine and grinder. The app adapts its dial-in tools to exactly how you grind."),
        .init(systemImage: "leaf.fill", title: "Your Coffee", subtitle: "Build a library of beans, track freshness off-roast, and add new bags in seconds."),
        .init(systemImage: "dial.medium.fill", title: "Dial It In", subtitle: "Capture every parameter, taste the shot, and get coaching to fix what's off."),
        .init(systemImage: "chart.line.uptrend.xyaxis", title: "Track Progress", subtitle: "Save golden recipes and watch your coffee get better over time."),
        .init(systemImage: "lock.fill", title: "Private by Design", subtitle: "Your beans, shots, café memories and photos live only on this device. No accounts, no feeds — just your private coffee journal.")
    ]

    var body: some View {
        ZStack {
            CremaColor.background.ignoresSafeArea()
            warmGlow

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        HapticEngine.light()
                        finish()
                    }
                    .font(.crema(16, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
                    .padding()
                }

                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: index)

                pageDots
                    .padding(.bottom, 24)

                PrimaryButton(title: index == pages.count - 1 ? "Start Brewing" : "Continue", systemImage: index == pages.count - 1 ? "checkmark" : "arrow.right") {
                    if index == pages.count - 1 {
                        finish()
                    } else {
                        withAnimation { index += 1 }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(CremaColor.crema.opacity(0.16))
                    .frame(width: 180, height: 180)
                Image(systemName: page.systemImage)
                    .font(.system(size: 76, weight: .medium))
                    .foregroundStyle(CremaColor.crema)
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.crema(34, .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(CremaColor.textPrimary)
                Text(page.subtitle)
                    .font(.crema(17))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(CremaColor.textSecondary)
                    .padding(.horizontal, 36)
            }
            Spacer()
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? CremaColor.espresso : CremaColor.separator)
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: index)
            }
        }
    }

    private var warmGlow: some View {
        RadialGradient(
            colors: [CremaColor.crema.opacity(0.18), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 420
        )
        .ignoresSafeArea()
    }

    private func finish() {
        withAnimation { hasOnboarded = true }
    }
}
