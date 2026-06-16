//
//  BeansView.swift
//  CremaDialed
//

import SwiftUI
import SwiftData

struct BeansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bean.createdAt, order: .reverse) private var beans: [Bean]
    @State private var showAdd = false
    @State private var search = ""

    private var active: [Bean] { filtered.filter { !$0.isFinished } }
    private var finished: [Bean] { filtered.filter { $0.isFinished } }

    private var filtered: [Bean] {
        guard !search.isEmpty else { return beans }
        return beans.filter {
            $0.name.localizedStandardContains(search) ||
            $0.roaster.localizedStandardContains(search) ||
            $0.country.localizedStandardContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                Group {
                    if beans.isEmpty {
                        EmptyStateView(
                            systemImage: "leaf.fill",
                            title: "No beans yet",
                            message: "Add your first bag to start tracking freshness and dialing in."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(active) { bean in
                                    NavigationLink(value: bean) { BeanCard(bean: bean) }
                                        .buttonStyle(PressableStyle())
                                }
                                if !finished.isEmpty {
                                    SectionHeader("Finished")
                                        .padding(.top, 8)
                                    ForEach(finished) { bean in
                                        NavigationLink(value: bean) { BeanCard(bean: bean).opacity(0.6) }
                                            .buttonStyle(PressableStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Beans")
            .searchable(text: $search, prompt: "Search beans or roasters")
            .navigationDestination(for: Bean.self) { BeanDetailView(bean: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticEngine.tap()
                        showAdd = true
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddBeanSheet { newBean in
                    modelContext.insert(newBean)
                    HapticEngine.success()
                }
            }
        }
    }
}

struct BeanCard: View {
    let bean: Bean

    var body: some View {
        CremaCard {
            HStack(spacing: 14) {
                beanThumb
                VStack(alignment: .leading, spacing: 4) {
                    Text(bean.name)
                        .font(.crema(17, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                        .lineLimit(1)
                    if !bean.roaster.isEmpty {
                        Text(bean.roaster)
                            .font(.crema(14, .medium))
                            .foregroundStyle(CremaColor.textSecondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.crema(11))
                        Text(bean.freshnessLabel)
                            .font(.crema(12, .medium))
                    }
                    .foregroundStyle(freshnessTint)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.crema(13, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
            }
        }
    }

    private var freshnessTint: Color {
        guard let days = bean.daysOffRoast else { return CremaColor.textTertiary }
        switch days {
        case 4...18: return CremaColor.positive
        case ..<4, 19...30: return CremaColor.warning
        default: return CremaColor.negative
        }
    }

    @ViewBuilder private var beanThumb: some View {
        if let data = bean.photoData, let image = UIImage(data: data) {
            Color(.secondarySystemBackground)
                .frame(width: 56, height: 56)
                .overlay { Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false) }
                .clipShape(.rect(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(CremaColor.surface)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.crema(22))
                        .foregroundStyle(CremaColor.crema)
                }
        }
    }
}
