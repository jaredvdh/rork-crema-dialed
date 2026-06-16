//
//  RootView.swift
//  CremaDialed
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage(CremaDataStore.didResetStoreKey) private var didResetStore: Bool = false
    @AppStorage(AppSettings.appearanceKey) private var appearanceRaw: String = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode { AppearanceMode(rawValue: appearanceRaw) ?? .system }

    var body: some View {
        Group {
            if hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        .tint(CremaColor.espresso)
        .alert("Local Data Was Reset", isPresented: $didResetStore) {
            Button("OK", role: .cancel) { didResetStore = false }
        } message: {
            Text("We couldn't open your saved coffee data on this device, so it had to be reset to keep the app working. Any brews, beans and café visits stored only on this phone may have been cleared.")
        }
    }
}

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(CremaColor.card)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            DialInView()
                .tabItem { Label("Dial In", systemImage: "dial.medium.fill") }
            BeansView()
                .tabItem { Label("Beans", systemImage: "leaf.fill") }
            CafesView()
                .tabItem { Label("Cafés", systemImage: "mappin.and.ellipse") }
            HistoryView()
                .tabItem { Label("Journal", systemImage: "book.closed.fill") }
        }
    }
}
