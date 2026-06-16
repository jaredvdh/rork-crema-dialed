//
//  RootView.swift
//  CremaDialed
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false

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
        .tint(CremaColor.espresso)
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
            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.bar.fill") }
        }
    }
}
