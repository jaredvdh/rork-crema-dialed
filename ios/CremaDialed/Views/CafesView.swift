//
//  CafesView.swift
//  CremaDialed
//
//  The Coffee Passport experience, split into two journeys:
//    • Nearby   — discover coffee, get directions, check in.
//    • Passport — your personal coffee journal: stats, map and collections.
//

import SwiftUI
import SwiftData
import MapKit

/// A request to begin a check-in, optionally pre-seeded with a café.
struct CheckInRequest: Identifiable {
    let id = UUID()
    var result: CafeResult? = nil
    var existing: Cafe? = nil
}

/// Top-level sections of the Cafés tab.
enum CafeSegment: String, CaseIterable, Identifiable {
    case nearby = "Nearby"
    case passport = "Passport"
    var id: String { rawValue }
}

struct CafesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Cafe.createdAt, order: .reverse) private var cafes: [Cafe]

    @State private var location = CafeLocationService()
    @State private var segment: CafeSegment = .nearby
    @State private var checkInRequest: CheckInRequest?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                CremaColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    segmentPicker

                    switch segment {
                    case .nearby:
                        NearbyView(
                            location: location,
                            cafes: cafes,
                            onCheckIn: { checkInRequest = $0 },
                            onOpen: { result in path.append(ensureCafe(for: result).id) }
                        )
                    case .passport:
                        PassportView(
                            cafes: cafes,
                            onCheckIn: { checkInRequest = CheckInRequest() },
                            onDelete: deleteCafe
                        )
                    }
                }

                checkInButton
            }
            .navigationTitle(segment == .nearby ? "Find Coffee" : "Coffee Passport")
            .navigationDestination(for: UUID.self) { id in
                if let cafe = cafes.first(where: { $0.id == id }) {
                    CafeDetailView(cafe: cafe) { checkInRequest = CheckInRequest(existing: cafe) }
                }
            }
            .sheet(item: $checkInRequest) { request in
                CheckInView(
                    location: location,
                    existingCafes: cafes,
                    preselectedResult: request.result,
                    preselectedCafe: request.existing
                ) { cafe, visit in
                    if cafe.modelContext == nil { modelContext.insert(cafe) }
                    modelContext.insert(visit)
                }
            }
        }
    }

    // MARK: Segment control

    private var segmentPicker: some View {
        Picker("Section", selection: $segment) {
            ForEach(CafeSegment.allCases) { s in Text(s.rawValue).tag(s) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .onChange(of: segment) { _, _ in HapticEngine.selection() }
    }

    // MARK: Floating check-in button

    private var checkInButton: some View {
        VStack {
            Spacer()
            Button {
                HapticEngine.tap()
                checkInRequest = CheckInRequest()
            } label: {
                Label("Check In", systemImage: "cup.and.saucer.fill")
                    .font(.crema(17, .bold))
                    .foregroundStyle(CremaColor.background)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: CremaColor.espresso.opacity(0.35), radius: 12, y: 5)
            }
            .buttonStyle(PressableStyle())
            .padding(.bottom, 16)
        }
    }

    // MARK: Helpers

    /// Returns the saved café for a discovered result, creating a lightweight
    /// (un-visited, non-wishlist) record on demand so the detail page can open.
    /// Such records stay invisible in the Passport until a check-in is logged.
    private func ensureCafe(for result: CafeResult) -> Cafe {
        if let match = matchingCafe(for: result, in: cafes) { return match }
        let cafe = Cafe(name: result.name, address: result.address, city: result.city,
                        latitude: result.coordinate.latitude, longitude: result.coordinate.longitude)
        modelContext.insert(cafe)
        return cafe
    }

    private func deleteCafe(_ cafe: Cafe) {
        modelContext.delete(cafe)
    }
}
