//
//  Recipe.swift
//  CremaDialed
//
//  Curated coffee-based recipes. Static, bundled data — no persistence needed.
//

import Foundation

/// A coffee-based drink recipe with steps and a suggested espresso base.
struct Recipe: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let category: RecipeCategory
    let minutes: Int
    let difficulty: Difficulty
    let systemImage: String
    /// Suggested espresso base, e.g. "Double · 18g in / 36g out".
    let espressoBase: String?
    let ingredients: [String]
    let steps: [String]
    let tip: String?

    enum Difficulty: String {
        case easy = "Easy"
        case medium = "Medium"
        case advanced = "Advanced"
    }
}

enum RecipeCategory: String, CaseIterable, Identifiable {
    case milk = "Milk Drinks"
    case black = "Black & Long"
    case iced = "Iced & Cold"
    case signature = "Signature"
    case cocktail = "Cocktails"
    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .milk: return "cup.and.heat.waves.fill"
        case .black: return "cup.and.saucer.fill"
        case .iced: return "snowflake"
        case .signature: return "sparkles"
        case .cocktail: return "wineglass.fill"
        }
    }
}

/// The bundled recipe library.
enum RecipeLibrary {
    static let all: [Recipe] = [
        // MARK: Milk drinks
        Recipe(
            id: "flat-white",
            name: "Flat White",
            tagline: "Silky microfoam over a punchy double",
            category: .milk,
            minutes: 4,
            difficulty: .medium,
            systemImage: "cup.and.heat.waves.fill",
            espressoBase: "Double ristretto · 18g in / 36g out",
            ingredients: ["18g coffee", "120ml whole milk", "Ceramic 150–180ml cup"],
            steps: [
                "Pull a double ristretto shot straight into the cup.",
                "Steam 120ml of milk to 60–63°C, aiming for glossy, paint-like microfoam.",
                "Tap and swirl the jug to integrate the foam.",
                "Pour from a height to combine, then drop low to float a small dot of foam.",
                "Aim for ~1cm of velvety foam — no dry crust."
            ],
            tip: "Keep the foam thin: a flat white should look flat, not domed."
        ),
        Recipe(
            id: "cappuccino",
            name: "Cappuccino",
            tagline: "Equal espresso, milk and airy foam",
            category: .milk,
            minutes: 4,
            difficulty: .medium,
            systemImage: "cup.and.heat.waves.fill",
            espressoBase: "Double · 18g in / 36g out",
            ingredients: ["18g coffee", "120ml whole milk", "150ml cup"],
            steps: [
                "Pull a balanced double shot.",
                "Stretch the milk longer than a flat white for a thicker foam (~1.5cm).",
                "Steam to 60–65°C.",
                "Pour to keep roughly equal thirds of espresso, milk and foam.",
                "Dust with cocoa if you like."
            ],
            tip: "More stretch early in steaming builds the classic domed foam."
        ),
        Recipe(
            id: "latte",
            name: "Café Latte",
            tagline: "Smooth, milky and forgiving",
            category: .milk,
            minutes: 4,
            difficulty: .easy,
            systemImage: "cup.and.heat.waves.fill",
            espressoBase: "Double · 18g in / 36g out",
            ingredients: ["18g coffee", "220ml whole milk", "Tall 250–300ml glass"],
            steps: [
                "Pull a double shot into a large glass or cup.",
                "Steam 220ml milk to 60–63°C with just a thin layer of foam.",
                "Swirl until glossy.",
                "Pour steadily, finishing with a simple heart or tulip.",
                "Serve immediately while hot."
            ],
            tip: "Latte = more milk, less foam. Keep texture silky, not bubbly."
        ),
        Recipe(
            id: "cortado",
            name: "Cortado",
            tagline: "Espresso cut with a little warm milk",
            category: .milk,
            minutes: 3,
            difficulty: .easy,
            systemImage: "cup.and.heat.waves.fill",
            espressoBase: "Double · 18g in / 36g out",
            ingredients: ["18g coffee", "60ml whole milk", "Gibraltar / 120ml glass"],
            steps: [
                "Pull a double shot into a small glass.",
                "Steam 60ml milk to a thin, barely-there foam.",
                "Pour 1:1 espresso to milk.",
                "No latte art needed — keep it tight and balanced."
            ],
            tip: "The cortado is all about balance: enough milk to round the edges, not drown the coffee."
        ),

        // MARK: Black & long
        Recipe(
            id: "americano",
            name: "Americano",
            tagline: "Espresso lengthened with hot water",
            category: .black,
            minutes: 2,
            difficulty: .easy,
            systemImage: "cup.and.saucer.fill",
            espressoBase: "Double · 18g in / 36g out",
            ingredients: ["18g coffee", "120–180ml hot water"],
            steps: [
                "Add hot water (90°C) to the cup first.",
                "Pull a double shot on top to preserve the crema.",
                "Adjust strength with more or less water to taste."
            ],
            tip: "Water first keeps the crema intact and the drink less bitter."
        ),
        Recipe(
            id: "long-black",
            name: "Long Black",
            tagline: "Crema-forward and intense",
            category: .black,
            minutes: 2,
            difficulty: .easy,
            systemImage: "cup.and.saucer.fill",
            espressoBase: "Double ristretto · 18g in / 36g out",
            ingredients: ["18g coffee", "90–120ml hot water"],
            steps: [
                "Pour hot water into the cup (about two-thirds full).",
                "Pull a double shot directly over the water.",
                "Serve straight away with the crema on top."
            ],
            tip: "Shorter and stronger than an Americano — don't over-dilute."
        ),

        // MARK: Iced & cold
        Recipe(
            id: "iced-latte",
            name: "Iced Latte",
            tagline: "Chilled, smooth and refreshing",
            category: .iced,
            minutes: 4,
            difficulty: .easy,
            systemImage: "snowflake",
            espressoBase: "Double · 18g in / 40g out",
            ingredients: ["18g coffee", "150ml cold milk", "Plenty of ice", "Tall glass"],
            steps: [
                "Fill a tall glass with ice.",
                "Pour cold milk over the ice.",
                "Pull a double shot and pour gently over the back of a spoon for layers.",
                "Stir before drinking."
            ],
            tip: "Pull the shot slightly longer so flavour isn't lost when diluted by ice."
        ),
        Recipe(
            id: "espresso-tonic",
            name: "Espresso Tonic",
            tagline: "Bittersweet, sparkling and bright",
            category: .iced,
            minutes: 3,
            difficulty: .medium,
            systemImage: "snowflake",
            espressoBase: "Double · 18g in / 36g out",
            ingredients: ["18g coffee", "150ml tonic water", "Ice", "Orange or lime slice"],
            steps: [
                "Fill a glass with ice and pour in chilled tonic water.",
                "Let the tonic settle so it doesn't foam over.",
                "Pull a double shot and pour slowly over the back of a spoon.",
                "Garnish with citrus and serve unstirred for the layered look."
            ],
            tip: "Use a fruity, light-roast espresso — it sings against the tonic's bitterness."
        ),
        Recipe(
            id: "cold-brew",
            name: "Cold Brew",
            tagline: "Smooth, low-acid, slow-steeped",
            category: .iced,
            minutes: 12,
            difficulty: .easy,
            systemImage: "snowflake",
            espressoBase: nil,
            ingredients: ["100g coarse ground coffee", "1L cold filtered water", "Jar or carafe"],
            steps: [
                "Combine coarse grounds and cold water at a 1:10 ratio.",
                "Stir to fully saturate, then cover.",
                "Steep in the fridge for 12–18 hours.",
                "Strain through a filter, then dilute to taste over ice."
            ],
            tip: "A medium-dark roast gives chocolatey, smooth cold brew."
        ),

        // MARK: Signature
        Recipe(
            id: "affogato",
            name: "Affogato",
            tagline: "Espresso drowned over vanilla gelato",
            category: .signature,
            minutes: 2,
            difficulty: .easy,
            systemImage: "sparkles",
            espressoBase: "Single or double · 18g in / 36g out",
            ingredients: ["1 scoop vanilla gelato", "Single or double espresso", "Chilled glass"],
            steps: [
                "Place a scoop of vanilla gelato in a chilled glass.",
                "Pull a fresh, hot shot.",
                "Pour the espresso over the gelato at the table.",
                "Serve immediately with a spoon."
            ],
            tip: "Pull the shot last so the contrast of hot and cold is dramatic."
        ),
        Recipe(
            id: "cortadito",
            name: "Cuban Cortadito",
            tagline: "Sweet, whipped espumita on top",
            category: .signature,
            minutes: 5,
            difficulty: .medium,
            systemImage: "sparkles",
            espressoBase: "Double · 18g in / 36g out",
            ingredients: ["18g dark-roast coffee", "1–2 tsp sugar", "60ml steamed milk"],
            steps: [
                "Whip the first few drops of espresso with the sugar until pale and creamy (espuma).",
                "Pull the rest of the shot into the whipped sugar.",
                "Top with an equal part of steamed milk.",
                "Stir gently and enjoy."
            ],
            tip: "The whipped sugar 'espuma' is the signature — beat it vigorously."
        ),

        // MARK: Cocktails
        Recipe(
            id: "espresso-martini",
            name: "Espresso Martini",
            tagline: "Velvety, boozy and wide awake",
            category: .cocktail,
            minutes: 5,
            difficulty: .advanced,
            systemImage: "wineglass.fill",
            espressoBase: "Double · 18g in / 36g out (cooled)",
            ingredients: ["50ml vodka", "30ml coffee liqueur", "1 fresh double espresso", "Ice", "3 coffee beans"],
            steps: [
                "Pull a fresh double shot and let it cool slightly.",
                "Add vodka, coffee liqueur and espresso to a shaker with ice.",
                "Shake hard for 15–20 seconds to build a thick foam.",
                "Double-strain into a chilled coupe.",
                "Float three coffee beans on the crema."
            ],
            tip: "Shake harder and longer than you think — that's what creates the signature crema."
        ),
        Recipe(
            id: "irish-coffee",
            name: "Irish Coffee",
            tagline: "Warming whiskey, coffee and cream",
            category: .cocktail,
            minutes: 5,
            difficulty: .medium,
            systemImage: "wineglass.fill",
            espressoBase: nil,
            ingredients: ["120ml hot strong coffee", "40ml Irish whiskey", "1 tsp brown sugar", "Lightly whipped cream"],
            steps: [
                "Warm a glass with hot water, then empty it.",
                "Add brown sugar and hot coffee, stir to dissolve.",
                "Stir in the whiskey.",
                "Float lightly whipped cream over the back of a spoon.",
                "Sip the hot coffee through the cool cream — don't stir."
            ],
            tip: "Cream should be just thick enough to float but still pourable."
        )
    ]

    static func grouped() -> [(RecipeCategory, [Recipe])] {
        RecipeCategory.allCases.compactMap { category in
            let items = all.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }
}
