//
//  RecipesView.swift
//  CremaDialed
//
//  Browse curated coffee-based recipes, grouped by style.
//

import SwiftUI

struct RecipesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: RecipeCategory? = nil

    private var groups: [(RecipeCategory, [Recipe])] {
        RecipeLibrary.grouped().filter { selectedCategory == nil || $0.0 == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CremaColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        categoryFilter
                        ForEach(groups, id: \.0.id) { category, recipes in
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(category.rawValue)
                                ForEach(recipes) { recipe in
                                    NavigationLink(value: recipe) {
                                        RecipeRow(recipe: recipe)
                                    }
                                    .buttonStyle(PressableStyle())
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.crema(16, .semibold))
                        .foregroundStyle(CremaColor.espresso)
                }
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CremaChip(label: "All", systemImage: "square.grid.2x2.fill",
                          isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(RecipeCategory.allCases) { category in
                    CremaChip(label: category.rawValue, systemImage: category.systemImage,
                              isSelected: selectedCategory == category) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
            }
        }
    }
}

/// Compact card row for a recipe in the list.
struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        CremaCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(colors: [CremaColor.espresso, CremaColor.caramel],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: recipe.systemImage)
                        .font(.crema(20, .bold))
                        .foregroundStyle(CremaColor.background)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.name)
                        .font(.crema(17, .bold))
                        .foregroundStyle(CremaColor.textPrimary)
                    Text(recipe.tagline)
                        .font(.crema(13, .medium))
                        .foregroundStyle(CremaColor.textSecondary)
                        .lineLimit(2)
                    HStack(spacing: 10) {
                        metaLabel("clock", "\(recipe.minutes) min")
                        metaLabel("chart.bar.fill", recipe.difficulty.rawValue)
                    }
                    .padding(.top, 2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.crema(13, .semibold))
                    .foregroundStyle(CremaColor.textTertiary)
            }
        }
    }

    private func metaLabel(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.crema(10, .semibold))
            Text(text)
                .font(.crema(11, .semibold))
        }
        .foregroundStyle(CremaColor.crema)
    }
}
