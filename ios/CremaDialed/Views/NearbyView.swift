//
//  NearbyView.swift
//  CremaDialed
//
//  Discovery: find coffee houses and cafés around you, get directions, or
//  start a check-in — all before you ever set foot inside.
//

import SwiftUI
import MapKit
import CoreLocation

struct NearbyView: View {
    var location: CafeLocationService
    var cafes: [Cafe]
    /// Begin a check-in for a discovered café.
    var onCheckIn: (CheckInRequest) -> Void
    /// Open the full café detail page (caller ensures the café is persisted).
    var onOpen: (CafeResult) -> Void

    @AppStorage(AppSettings.locationKey) private var locationEnabled: Bool = true

    @State private var query = ""
    @State private var searchResults: [CafeResult] = []
    @State private var isSearching = false
    @State private var mode: BrowseMode = .list
    @State private var mapPosition: MapCameraPosition = .automatic

    enum BrowseMode: String, CaseIterable { case list = "List", map = "Map" }

    /// Results to display — search results when searching, otherwise nearby.
    private var displayed: [CafeResult] {
        query.isEmpty ? location.nearby : searchResults
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(CremaColor.background)
        .onAppear { if locationEnabled { location.requestAndLocate() } }
        .onChange(of: query) { _, q in
            Task {
                isSearching = true
                searchResults = await location.search(query: q)
                isSearching = false
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                searchField
                modeToggle
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CremaColor.textTertiary)
            TextField("Search cafés & coffee houses", text: $query)
                .font(.crema(16, .medium))
                .foregroundStyle(CremaColor.textPrimary)
                .tint(CremaColor.crema)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(CremaColor.textTertiary)
                }
            }
        }
        .padding(13)
        .background(CremaColor.surface)
        .clipShape(.rect(cornerRadius: CremaRadius.field))
    }

    private var modeToggle: some View {
        Button {
            HapticEngine.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                mode = mode == .list ? .map : .list
            }
        } label: {
            Image(systemName: mode == .list ? "map.fill" : "list.bullet")
                .font(.crema(17, .semibold))
                .foregroundStyle(CremaColor.background)
                .frame(width: 48, height: 48)
                .background(CremaColor.espresso)
                .clipShape(.rect(cornerRadius: CremaRadius.field))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if location.authorization == .notDetermined && query.isEmpty {
            ScrollView { permissionCard.padding(16) }
        } else if location.isDenied && query.isEmpty && location.nearby.isEmpty {
            ScrollView { deniedCard.padding(16) }
        } else if mode == .map {
            mapView
        } else {
            listView
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isSearching || (location.isSearching && location.nearby.isEmpty && query.isEmpty) {
                    ProgressView()
                        .tint(CremaColor.crema)
                        .padding(.top, 40)
                } else if displayed.isEmpty {
                    emptyResults
                } else {
                    ForEach(displayed) { result in
                        NearbyCafeCard(
                            result: result,
                            saved: matchingCafe(for: result, in: cafes),
                            onDirections: { MapsLauncher.directions(to: result.coordinate, name: result.name) },
                            onCheckIn: { onCheckIn(CheckInRequest(result: result)) },
                            onDetails: { onOpen(result) }
                        )
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var mapView: some View {
        Map(position: $mapPosition) {
            UserAnnotation()
            ForEach(displayed) { result in
                Annotation(result.name, coordinate: result.coordinate) {
                    Button {
                        HapticEngine.tap()
                        onOpen(result)
                    } label: {
                        ZStack {
                            Circle().fill(CremaColor.espresso)
                                .frame(width: 36, height: 36)
                                .shadow(radius: 3)
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(CremaColor.background)
                        }
                    }
                }
            }
        }
        .mapControls { MapUserLocationButton() }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: States

    private var emptyResults: some View {
        EmptyStateView(
            systemImage: "cup.and.saucer",
            title: query.isEmpty ? "No coffee nearby yet" : "No cafés found",
            message: query.isEmpty
                ? "We couldn't find cafés around you right now. Try searching by name above."
                : "Try a different name or area."
        )
        .padding(.top, 20)
    }

    private var permissionCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Find coffee around you", systemImage: "location.fill")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text("Allow location access to discover the closest cafés and coffee houses, sorted by distance.")
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
                PrimaryButton(title: "Enable Location", systemImage: "location") {
                    location.requestAndLocate()
                }
            }
        }
    }

    private var deniedCard: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Location is off", systemImage: "location.slash.fill")
                    .font(.crema(16, .bold))
                    .foregroundStyle(CremaColor.textPrimary)
                Text("Enable location in Settings, or search for a café by name above.")
                    .font(.crema(14, .medium))
                    .foregroundStyle(CremaColor.textSecondary)
            }
        }
    }
}
