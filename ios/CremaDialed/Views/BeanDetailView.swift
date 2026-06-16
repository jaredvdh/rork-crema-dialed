//
//  BeanDetailView.swift
//  CremaDialed
//

import SwiftUI
import SwiftData

struct BeanDetailView: View {
    @Bindable var bean: Bean
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allBrews: [Brew]
    @Query private var goldens: [DialedRecipe]

    private var beanBrews: [Brew] {
        allBrews.filter { $0.bean?.id == bean.id }.sorted { $0.date > $1.date }
    }
    private var golden: DialedRecipe? {
        goldens.first { $0.bean?.id == bean.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if let golden {
                    SectionHeader("Golden Recipe")
                    GoldenRecipeCard(recipe: golden)
                }

                CremaCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow("Origin", bean.originLine.isEmpty ? "—" : bean.originLine)
                        detailRow("Farm", bean.farm.isEmpty ? "—" : bean.farm)
                        detailRow("Variety", bean.variety.isEmpty ? "—" : bean.variety)
                        detailRow("Process", bean.process.rawValue)
                        detailRow("Roast", bean.roastLevel.rawValue)
                        if let date = bean.roastDate {
                            detailRow("Roasted", date.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }

                if !bean.notes.isEmpty {
                    CremaCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOTES")
                                .font(.crema(11, .semibold))
                                .foregroundStyle(CremaColor.textTertiary)
                            Text(bean.notes)
                                .font(.crema(15))
                                .foregroundStyle(CremaColor.textPrimary)
                        }
                    }
                }

                SectionHeader("Brews") {
                    Text("\(beanBrews.count)")
                        .font(.crema(15, .semibold))
                        .foregroundStyle(CremaColor.textSecondary)
                }
                if beanBrews.isEmpty {
                    Text("No brews logged for this bean yet.")
                        .font(.crema(14))
                        .foregroundStyle(CremaColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(beanBrews) { brew in
                        NavigationLink(value: brew) { BrewRow(brew: brew) }
                            .buttonStyle(PressableStyle())
                    }
                }
            }
            .padding(16)
        }
        .background(CremaColor.background)
        .navigationTitle(bean.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Brew.self) { BrewDetailView(brew: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        bean.isFinished.toggle()
                        HapticEngine.tap()
                    } label: {
                        Label(bean.isFinished ? "Mark as active" : "Mark as finished",
                              systemImage: bean.isFinished ? "arrow.uturn.backward" : "checkmark")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(bean)
                        HapticEngine.warning()
                        dismiss()
                    } label: { Label("Delete bean", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            if let data = bean.photoData, let image = UIImage(data: data) {
                Color(.secondarySystemBackground)
                    .frame(height: 200)
                    .overlay { Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false) }
                    .clipShape(.rect(cornerRadius: CremaRadius.card))
            }
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                Text(bean.freshnessLabel)
            }
            .font(.crema(15, .semibold))
            .foregroundStyle(CremaColor.background)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(CremaColor.caramel)
            .clipShape(.rect(cornerRadius: CremaRadius.field))
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.crema(15, .medium))
                .foregroundStyle(CremaColor.textSecondary)
            Spacer()
            Text(value)
                .font(.crema(15, .semibold))
                .foregroundStyle(CremaColor.textPrimary)
        }
    }
}

struct GoldenRecipeCard: View {
    let recipe: DialedRecipe

    var body: some View {
        CremaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(CremaColor.crema)
                    Text("Dialed In · scored \(recipe.score)/10")
                        .font(.crema(15, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                }
                HStack(spacing: 10) {
                    goldenStat("Dose", String(format: "%.1fg", recipe.dose))
                    goldenStat("Yield", String(format: "%.1fg", recipe.yield))
                    goldenStat("Ratio", recipe.ratioLabel)
                    goldenStat("Time", String(format: "%.0fs", recipe.shotTime))
                }
                if !recipe.grindSetting.isEmpty {
                    Text("Grind: \(recipe.grindSetting)")
                        .font(.crema(13, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                }
            }
        }
    }

    private func goldenStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.crema(17, .bold))
                .foregroundStyle(CremaColor.crema)
            Text(label.uppercased())
                .font(.crema(10, .semibold))
                .foregroundStyle(CremaColor.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
